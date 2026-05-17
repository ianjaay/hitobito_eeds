# frozen_string_literal: true

module Eeds
  # Importe des personnes depuis les données parsées d'un fichier Excel.
  #
  # Pour chaque ligne :
  #  1. Résout les groupes cibles en parcourant les paires (groupe, rôle) par niveau
  #  2. Cherche un doublon (email ou prénom+nom+date de naissance)
  #  3. Crée ou met à jour la personne
  #  4. Attribue un rôle dans chaque groupe où une colonne rôle est renseignée
  class ExcelImporter
    include Translatable

    attr_reader :group, :rows, :results, :errors,
                :new_count, :update_count, :failure_count, :role_count

    PERSON_FIELD_MAP = {
      "Prénom"                       => :first_name,
      "Nom"                          => :last_name,
      "Surnom"                       => :nickname,
      "E-Mail"                       => :email,
      "Téléphone"                    => :phone_number,
      "Date de naissance"            => :birthday,
      "Genre (m/w)"                  => :gender,
      "Lieu de naissance"            => :birthplace,
      "Nationalité"                  => :nationality,
      "Région administrative"        => :administrative_region,
      "Contact d'urgence - Nom"      => :emergency_contact_name,
      "Contact d'urgence - Tél"      => :emergency_contact_phone,
      "Contact d'urgence - Lien"     => :emergency_contact_relation
    }.freeze

    # Correspondance label colonne → type de groupe interne
    HIERARCHY_LABELS = {
      "Région"       => "Group::Kantonalverband",
      "District"     => "Group::Region",
      "Groupe local" => "Group::Abteilung",
      "Unité"        => :unit,
      "Sous-groupe"  => "Group::Subgroup"
    }.freeze

    UNIT_TYPES = %w[Group::Woelfe Group::Pfadi Group::Pio Group::Rover].freeze

    def initialize(group, rows, user_ability: nil)
      @group = group
      @rows = rows
      @user_ability = user_ability
      @results = []
      @errors = []
      @new_count = 0
      @update_count = 0
      @failure_count = 0
      @role_count = 0
    end

    # Dry-run : valide toutes les lignes sans sauvegarder
    def preview
      @results = rows.each_with_index.map { |row, i| process_row(row, i, save: false) }
      self
    end

    # Import effectif
    def import!
      @results = rows.each_with_index.map { |row, i| process_row(row, i, save: true) }
      self
    end

    def total_count
      rows.size
    end

    private

    # -------------------------------------------------------------------
    # Traitement d'une ligne : personne + rôles multiples
    # -------------------------------------------------------------------
    def process_row(row, index, save: false)
      result = { row: index + 1, data: row, status: nil, person: nil,
                 errors: [], role_assignments: [] }

      # 1. Extraire les attributs personne
      person_attrs = extract_person_attributes(row)

      if person_attrs[:first_name].blank? && person_attrs[:last_name].blank?
        result[:status] = :error
        result[:errors] << "Prénom et/ou Nom requis (ligne #{index + 1})"
        @failure_count += 1
        return result
      end

      # 2. Résoudre tous les groupes + rôles demandés
      role_assignments = resolve_all_role_assignments(row)
      row_errors = role_assignments.select { |ra| ra[:error] }.map { |ra| ra[:error] }

      if row_errors.present?
        result[:status] = :error
        result[:errors] = row_errors
        @failure_count += 1
        return result
      end

      # Filtrer les assignments vides (pas de rôle renseigné à ce niveau)
      role_assignments = role_assignments.select { |ra| ra[:role_type] }

      if role_assignments.empty?
        result[:status] = :error
        result[:errors] << "Aucun rôle spécifié sur aucun niveau"
        @failure_count += 1
        return result
      end

      # 3. Trouver ou créer la personne
      person = find_existing_person(person_attrs) || ::Person.new
      is_new = person.new_record?
      assign_person_attributes(person, person_attrs)

      unless person.valid?
        result[:status] = :error
        result[:errors] = person.errors.full_messages
        @failure_count += 1
        result[:person] = person
        return result
      end

      # 4. Préparer les détails pour la prévisualisation
      result[:person] = person
      result[:role_assignments] = role_assignments

      if save
        ::Person.transaction do
          person.save!

          phone = row["Téléphone"].presence
          if phone && !person.phone_numbers.exists?(number: phone)
            person.phone_numbers.create!(number: phone, label: "GSM")
          end

          role_assignments.each do |ra|
            target_group = ra[:group]
            role_type = ra[:role_type]

            # Ne pas recréer un rôle qui existe déjà
            existing = person.persisted? &&
              person.roles.find { |r| r.group_id == target_group.id && r.type == role_type.sti_name }
            next if existing

            role = person.roles.build
            role.group = target_group
            role.type = role_type.sti_name
            role.save!
            @role_count += 1
          end
        end
      end

      if is_new
        result[:status] = :new
        @new_count += 1
      else
        result[:status] = :updated
        @update_count += 1
      end

      result
    rescue ActiveRecord::RecordInvalid => e
      result[:status] = :error
      result[:errors] = [e.message]
      @failure_count += 1
      result
    end

    # -------------------------------------------------------------------
    # Résolution de TOUS les groupes + rôles pour une ligne.
    #
    # On parcourt les niveaux hiérarchiques disponibles. Pour chaque
    # niveau, on regarde la colonne groupe et la colonne rôle :
    #
    #  - Si la colonne groupe est remplie → on résout le groupe
    #  - Si la colonne rôle est remplie  → on résout le rôle pour ce groupe
    #  - Si seul le rôle est rempli (sans groupe enfant) → le rôle
    #    s'applique au dernier groupe résolu (le groupe courant au début)
    # -------------------------------------------------------------------
    def resolve_all_role_assignments(row)
      levels = available_hierarchy_levels
      assignments = []
      current_group = group

      levels.each_with_index do |level, level_idx|
        group_label = hierarchy_column_label(level)
        role_label  = "Rôle #{group_label}"

        group_value = row[group_label].to_s.strip
        role_value  = row[role_label].to_s.strip

        # Résoudre le groupe à ce niveau
        if group_value.present?
          if level_idx == 0
            # Premier niveau = le groupe courant lui-même
            # Vérifier que le nom correspond
            if group_value.downcase != current_group.name.downcase
              return [{ error: "#{group_label} « #{group_value} » ne correspond pas au groupe courant « #{current_group.name} »" }]
            end
          else
            types = (level == :unit) ? UNIT_TYPES : [level.to_s]
            child = current_group.children
                                 .without_deleted
                                 .where(type: types)
                                 .find_by("LOWER(name) = ?", group_value.downcase)
            if child.nil?
              return [{ error: "#{group_label} « #{group_value} » introuvable sous « #{current_group.name} »" }]
            end
            current_group = child
          end
        end

        # Résoudre le rôle si renseigné
        if role_value.present?
          role_resolution = resolve_role_for_group(role_value, current_group)
          if role_resolution[:error]
            return [role_resolution]
          end
          assignments << { group: current_group, role_type: role_resolution[:role_type], level_label: group_label }
        end
      end

      assignments
    end

    # Niveaux hiérarchiques disponibles (même logique que le template generator)
    def available_hierarchy_levels
      current_type = group.type
      all_hierarchy = %w[
        Group::Kantonalverband
        Group::Region
        Group::Abteilung
        Group::Woelfe Group::Pfadi Group::Pio Group::Rover
        Group::Subgroup
      ]
      idx = all_hierarchy.index(current_type)
      idx ||= all_hierarchy.index("Group::Woelfe") if UNIT_TYPES.include?(current_type)
      return [] if idx.nil?

      levels = all_hierarchy[idx..]
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

    def hierarchy_column_label(level)
      labels = {
        "Group::Kantonalverband" => "Région",
        "Group::Region"          => "District",
        "Group::Abteilung"       => "Groupe local",
        "Group::Subgroup"        => "Sous-groupe"
      }
      (level == :unit) ? "Unité" : (labels[level.to_s] || level.to_s)
    end

    # -------------------------------------------------------------------
    # Résolution du type de rôle pour un groupe donné
    # -------------------------------------------------------------------
    def resolve_role_for_group(role_label, target_group)
      # Chercher par label traduit
      matching = target_group.class.role_types.find { |rt| rt.label == role_label }
      return { role_type: matching } if matching

      # Essayer par nom de classe simplifié (ex: "Wolf", "Member")
      matching = target_group.class.role_types.find { |rt| rt.sti_name.demodulize == role_label }
      return { role_type: matching } if matching

      valid_roles = target_group.class.role_types.map(&:label).join(", ")
      { error: "Rôle « #{role_label} » invalide pour #{target_group.name} (#{target_group.class.label}). Rôles valides : #{valid_roles}" }
    end

    # -------------------------------------------------------------------
    # Extraction des attributs personne depuis la ligne Excel
    # -------------------------------------------------------------------
    def extract_person_attributes(row)
      attrs = {}
      PERSON_FIELD_MAP.each do |header, attr_name|
        value = row[header]
        next if value.blank?

        case attr_name
        when :birthday
          attrs[attr_name] = parse_date(value)
        when :phone_number
          next # Géré séparément via PhoneNumber
        else
          attrs[attr_name] = value
        end
      end
      attrs
    end

    def assign_person_attributes(person, attrs)
      attrs.each do |key, value|
        person.send(:"#{key}=", value) if person.respond_to?(:"#{key}=") && value.present?
      end
    end

    # -------------------------------------------------------------------
    # Recherche de doublons
    # -------------------------------------------------------------------
    def find_existing_person(attrs)
      # 1. Par email
      if attrs[:email].present?
        found = ::Person.find_by(email: attrs[:email].downcase)
        return found if found
      end

      # 2. Par prénom + nom + date de naissance
      if attrs[:first_name].present? && attrs[:last_name].present? && attrs[:birthday].present?
        found = ::Person.find_by(
          first_name: attrs[:first_name],
          last_name: attrs[:last_name],
          birthday: attrs[:birthday]
        )
        return found if found
      end

      nil
    end

    def parse_date(value)
      return value if value.is_a?(Date) || value.is_a?(DateTime)
      Date.parse(value.to_s)
    rescue Date::Error
      nil
    end
  end
end
