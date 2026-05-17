# frozen_string_literal: true

require "axlsx"

module Eeds
  # Génère un modèle Excel (.xlsx) pré-rempli pour l'import en masse de personnes.
  #
  # Feuille 1 « Données » :
  #   - En-têtes des champs personnels + colonnes hiérarchiques adaptées au niveau courant
  #   - Validation par liste déroulante sur les colonnes groupe et rôle
  #
  # Feuille 2 « Référence » :
  #   - Listes des groupes enfants existants en base, par niveau
  #   - Liste des rôles valides par type de groupe
  class ExcelTemplateGenerator
    # Colonnes de données personnelles (ordre d'affichage dans la feuille)
    PERSON_COLUMNS = %w[
      first_name last_name nickname email
      phone_number birthday gender
      birthplace nationality administrative_region
      emergency_contact_name emergency_contact_phone emergency_contact_relation
    ].freeze

    # Correspondance type de groupe interne PBS → nom affiché EEDS
    GROUP_TYPE_LABELS = {
      "Group::Kantonalverband" => "Région",
      "Group::Region"          => "District",
      "Group::Abteilung"       => "Groupe local",
      "Group::Woelfe"          => "Mbotaay",
      "Group::Pfadi"           => "Kayon",
      "Group::Pio"             => "Ñawka",
      "Group::Rover"           => "Gàlle",
      "Group::Subgroup"        => "Sous-groupe"
    }.freeze

    # Niveaux hiérarchiques ordonnés du plus haut au plus bas
    HIERARCHY = %w[
      Group::Kantonalverband
      Group::Region
      Group::Abteilung
      Group::Woelfe Group::Pfadi Group::Pio Group::Rover
      Group::Subgroup
    ].freeze

    # Types de groupe « unité » (même niveau hiérarchique)
    UNIT_TYPES = %w[Group::Woelfe Group::Pfadi Group::Pio Group::Rover].freeze

    attr_reader :group

    def initialize(group)
      @group = group
    end

    def generate
      package = Axlsx::Package.new
      wb = package.workbook

      ref_sheet = build_reference_sheet(wb)
      build_data_sheet(wb, ref_sheet)

      package.to_stream.read
    end

    private

    # -------------------------------------------------------------------
    # Détermine quels niveaux hiérarchiques sont disponibles à partir du
    # groupe courant (inclus). Ex : si on est sur une Région (Kantonalverband),
    # les niveaux sont Région, District, Groupe local, Unité, Sous-groupe.
    # Cela permet d'affecter des personnes directement au niveau courant
    # OU à n'importe quel sous-niveau.
    # -------------------------------------------------------------------
    def available_hierarchy_levels
      current_type = group.type
      idx = HIERARCHY.index(current_type)
      idx ||= HIERARCHY.index("Group::Woelfe") if UNIT_TYPES.include?(current_type)

      return [] if idx.nil?

      levels = HIERARCHY[idx..]
      return [] if levels.blank?

      # Fusionner les 4 types d'unités en un seul niveau « Unité »
      merged = []
      unit_added = false
      levels.each do |t|
        if UNIT_TYPES.include?(t)
          next if unit_added
          merged << :unit
          unit_added = true
        else
          merged << t
        end
      end
      merged
    end

    # Label d'en-tête pour une colonne hiérarchique
    def hierarchy_column_label(level)
      if level == :unit
        "Unité"
      else
        GROUP_TYPE_LABELS[level] || level
      end
    end

    # -------------------------------------------------------------------
    # Feuille 2 : Référence (groupes existants + rôles valides)
    # -------------------------------------------------------------------
    def build_reference_sheet(wb)
      wb.add_worksheet(name: "Référence") do |sheet|
        levels = available_hierarchy_levels
        return sheet if levels.empty?

        # --- Section 1 : Groupes existants par niveau ---
        sheet.add_row ["=== GROUPES EXISTANTS ==="], style: header_style(wb)
        sheet.add_row []

        @ref_ranges = {} # { level => "Référence!$X$start:$X$end" }
        col_index = 0

        # Pour le niveau courant, on inclut le nom du groupe lui-même
        # Pour les sous-niveaux, on récupère les enfants en base
        levels.each_with_index do |level, level_idx|
          names = if level_idx == 0
                    # Niveau courant = le groupe lui-même
                    [group.name]
                  else
                    fetch_group_names(level)
                  end
          next if names.empty?

          label = hierarchy_column_label(level)
          sheet.rows[2] ||= sheet.add_row([])

          write_reference_column(sheet, col_index, label, names)

          start_row = 4
          end_row = 3 + names.size
          col_letter = column_letter(col_index)
          @ref_ranges[level] = "Référence!$#{col_letter}$#{start_row}:$#{col_letter}$#{end_row}"

          col_index += 1
        end

        # --- Section 2 : Rôles valides par type de groupe (un bloc par niveau) ---
        roles_col = col_index + 1
        sheet.rows[2] ||= sheet.add_row([])

        levels.each do |level|
          group_types = resolve_group_types(level)
          group_types.each do |gt|
            write_role_reference(sheet, roles_col, gt)
            @ref_ranges[:"roles_#{gt.sti_name}"] = build_role_range(sheet, roles_col, gt)
            roles_col += 1
          end
        end
      end
    end

    def write_reference_column(sheet, col_index, label, names)
      # Ligne d'en-tête (row 2, 0-indexed)
      ensure_row(sheet, 2)
      set_cell(sheet, 2, col_index, label)

      # Données à partir de la ligne 3 (0-indexed)
      names.each_with_index do |name, i|
        row_idx = 3 + i
        ensure_row(sheet, row_idx)
        set_cell(sheet, row_idx, col_index, name)
      end
    end

    def write_role_reference(sheet, col_index, group_class)
      label = "Rôles - #{GROUP_TYPE_LABELS[group_class.sti_name] || group_class.label}"
      ensure_row(sheet, 2)
      set_cell(sheet, 2, col_index, label)

      role_labels = group_class.role_types.map { |rt| rt.label }
      role_labels.each_with_index do |rl, i|
        row_idx = 3 + i
        ensure_row(sheet, row_idx)
        set_cell(sheet, row_idx, col_index, rl)
      end
    end

    def build_role_range(sheet, col_index, group_class)
      count = group_class.role_types.size
      return nil if count == 0
      col_letter = column_letter(col_index)
      "Référence!$#{col_letter}$4:$#{col_letter}$#{3 + count}"
    end

    # -------------------------------------------------------------------
    # Récupère les noms des groupes existants en base pour un niveau donné
    # -------------------------------------------------------------------
    def fetch_group_names(level)
      types = (level == :unit) ? UNIT_TYPES : [level]
      Group.without_deleted
           .where(type: types)
           .where("lft > ? AND rgt < ?", group.lft, group.rgt)
           .order(:name)
           .pluck(:name)
           .uniq
    end

    # -------------------------------------------------------------------
    # Feuille 1 : Données (saisie par l'utilisateur)
    #
    # Structure des colonnes :
    #   [Champs personne] [Groupe niv.1] [Rôle niv.1] [Groupe niv.2] [Rôle niv.2] ...
    #
    # Chaque niveau hiérarchique a une colonne groupe + une colonne rôle.
    # Cela permet d'affecter des rôles différents à chaque niveau.
    # -------------------------------------------------------------------
    def build_data_sheet(wb, ref_sheet)
      wb.add_worksheet(name: "Données") do |sheet|
        levels = available_hierarchy_levels

        # Construire les en-têtes : champs personne + paires (Groupe, Rôle) par niveau
        headers = person_column_labels
        levels.each do |level|
          headers << hierarchy_column_label(level)
          headers << role_column_label(level)
        end

        sheet.add_row headers, style: header_style(wb)

        # Ajouter 500 lignes vides pour la saisie
        500.times { sheet.add_row Array.new(headers.size, nil) }

        # Appliquer les validations par liste déroulante
        apply_data_validations(sheet, levels, headers)
      end
    end

    # Label pour la colonne rôle d'un niveau donné
    def role_column_label(level)
      "Rôle #{hierarchy_column_label(level)}"
    end

    def person_column_labels
      PERSON_COLUMNS.map { |col| person_label(col) }
    end

    def person_label(attr)
      case attr
      when "phone_number" then "Téléphone"
      when "birthday" then "Date de naissance"
      when "gender" then "Genre (m/w)"
      when "birthplace" then "Lieu de naissance"
      when "nationality" then "Nationalité"
      when "administrative_region" then "Région administrative"
      when "emergency_contact_name" then "Contact d'urgence - Nom"
      when "emergency_contact_phone" then "Contact d'urgence - Tél"
      when "emergency_contact_relation" then "Contact d'urgence - Lien"
      else
        ::Person.human_attribute_name(attr, default: attr.humanize)
      end
    end

    # -------------------------------------------------------------------
    # Validations Excel (dropdown lists liées à la feuille Référence)
    #
    # Layout des colonnes après les champs personne :
    #   [Groupe niv.1] [Rôle niv.1] [Groupe niv.2] [Rôle niv.2] ...
    # -------------------------------------------------------------------
    def apply_data_validations(sheet, levels, headers)
      person_col_count = PERSON_COLUMNS.size

      levels.each_with_index do |level, i|
        group_col_idx = person_col_count + (i * 2)     # colonne groupe
        role_col_idx  = person_col_count + (i * 2) + 1 # colonne rôle

        # Validation dropdown sur la colonne groupe
        group_range = @ref_ranges&.dig(level)
        add_list_validation(sheet, group_col_idx, group_range) if group_range

        # Validation dropdown sur la colonne rôle (tous les rôles possibles pour ce niveau)
        role_labels = collect_role_labels_for_level(level)
        if role_labels.present?
          formula = %("#{role_labels.join(",")}")
          if formula.length > 255
            # Trop long — utiliser une référence depuis la feuille Référence
            ref_key = resolve_group_types(level).first
            range = @ref_ranges&.dig(:"roles_#{ref_key&.sti_name}")
            add_list_validation(sheet, role_col_idx, range) if range
          else
            add_inline_list_validation(sheet, role_col_idx, role_labels)
          end
        end
      end

      # Validation sur le genre
      gender_col = PERSON_COLUMNS.index("gender")
      add_inline_list_validation(sheet, gender_col, %w[m w]) if gender_col

      # Validation sur la région administrative
      admin_region_col = PERSON_COLUMNS.index("administrative_region")
      if admin_region_col && defined?(Eeds::Person::ADMINISTRATIVE_REGIONS)
        regions = Eeds::Person::ADMINISTRATIVE_REGIONS
        add_inline_list_validation(sheet, admin_region_col, regions) if regions.present?
      end
    end

    # Rôles valides pour un niveau hiérarchique donné
    def collect_role_labels_for_level(level)
      group_types = resolve_group_types(level)
      labels = []
      group_types.each { |gt| labels.concat(gt.role_types.map(&:label)) }
      labels.uniq.sort
    end

    # Résout les classes de groupe pour un niveau (gère le cas :unit)
    def resolve_group_types(level)
      (level == :unit) ? UNIT_TYPES.map(&:constantize) : [level.constantize]
    end

    def add_list_validation(sheet, col_idx, formula)
      col_letter = column_letter(col_idx)
      sqref = "#{col_letter}2:#{col_letter}501"
      sheet.add_data_validation(sqref, {
        type: :list,
        formula1: formula,
        showDropDown: false,
        errorStyle: :stop,
        error: "Veuillez choisir une valeur de la liste.",
        errorTitle: "Valeur invalide"
      })
    end

    def add_inline_list_validation(sheet, col_idx, values)
      col_letter = column_letter(col_idx)
      sqref = "#{col_letter}2:#{col_letter}501"
      sheet.add_data_validation(sqref, {
        type: :list,
        formula1: %("#{values.join(",")}"),
        showDropDown: false,
        errorStyle: :stop,
        error: "Veuillez choisir une valeur de la liste.",
        errorTitle: "Valeur invalide"
      })
    end

    # -------------------------------------------------------------------
    # Helpers
    # -------------------------------------------------------------------
    def header_style(wb)
      wb.styles.add_style(
        bg_color: "4472C4",
        fg_color: "FFFFFF",
        b: true,
        alignment: { horizontal: :center }
      )
    end

    def column_letter(index)
      result = +""
      loop do
        result.prepend(("A".ord + index % 26).chr)
        index = index / 26 - 1
        break if index < 0
      end
      result
    end

    def ensure_row(sheet, row_idx)
      while sheet.rows.size <= row_idx
        sheet.add_row []
      end
    end

    def set_cell(sheet, row_idx, col_idx, value)
      row = sheet.rows[row_idx]
      # Extend cells if needed
      while row.cells.size <= col_idx
        row.add_cell nil
      end
      row.cells[col_idx].value = value
    end
  end
end
