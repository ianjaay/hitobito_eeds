# frozen_string_literal: true

#  Adaptation Hitobito pour les Éclaireuses et Éclaireurs du Sénégal (E-Gàlle).
#  Ce wagon contient les spécificités EEDS qui s'ajoutent par-dessus hitobito_pbs.

module HitobitoEeds
  class Wagon < Rails::Engine
    include Wagons::Wagon

    app_requirement ">= 0"

    config.autoload_paths += %W[
      #{config.root}/app/abilities
      #{config.root}/app/controllers
      #{config.root}/app/domain
      #{config.root}/app/helpers
      #{config.root}/app/jobs
      #{config.root}/app/serializers
    ]

    config.to_prepare do
      ### models — extensions EEDS
      Person.include Eeds::Person
      QualificationKind.include Eeds::QualificationKindExtension

      ### controllers — retirer les attributs Suisse-spécifiques exposés par PBS
      # j_s_number = N° Jeunesse+Sport (programme suisse) — sans objet pour EEDS
      PeopleController.permitted_attrs -= [:j_s_number]
      # Ajouter les attributs EEDS aux paramètres autorisés
      PeopleController.permitted_attrs += [
        :birthplace, :nationality, :administrative_region,
        :emergency_contact_name, :emergency_contact_phone, :emergency_contact_relation,
        :has_family_in_scouting
      ]

      ### group types — retirer les attributs Suisse-spécifiques des groupes
      # cantons et group_health sont des concepts PBS/Suisse sans équivalent EEDS
      Group::Kantonalverband.used_attributes -= [:cantons, :group_health]

      ### group types — autoriser le sous-groupe sous chaque unité
      # (Mbotaay, Kayon, Ñawka, Gàlle = Woelfe, Pfadi, Pio, Rover en interne PBS)
      [Group::Woelfe, Group::Pfadi, Group::Pio, Group::Rover].each do |unit|
        unit.children(Group::Subgroup) unless unit.possible_children.include?(Group::Subgroup)
      end
      # Invalider les caches de types sans toucher aux root_types
      Group.class_variable_set(:@@all_types, nil) if Group.class_variable_defined?(:@@all_types)
      Role.reset_types!

      ### effectifs — retirer la branche Castor (biber) qui n'existe pas chez les EEDS
      MemberCount.const_set(:COUNT_CATEGORIES, [:leiter, :woelfe, :pfadis, :pios, :rover, :pta].freeze)
      MemberCount.const_set(:COUNT_COLUMNS, MemberCount::COUNT_CATEGORIES.collect { |c| [:"#{c}_f", :"#{c}_m"] }.flatten.freeze)

      ### navigation principale — ajouter Finance dans la barre du haut
      NavigationHelper.include Eeds::NavigationHelper

      # Exclure les chemins finance de la section Groupes
      groups_nav = NavigationHelper::MAIN.find { |opts| opts[:label] == :groups }
      if groups_nav
        groups_nav[:inactive_for] ||= []
        groups_nav[:inactive_for] << "finance"
      end

      index_admin = NavigationHelper::MAIN.index { |opts| opts[:label] == :admin }
      unless NavigationHelper::MAIN.any? { |opts| opts[:label] == :finances }
        NavigationHelper::MAIN.insert(
          index_admin,
          label: :finances,
          icon_name: "wallet",
          url: :first_group_finance_or_root_path,
          active_for: %w[finance/dashboard finance/activity_fees finance/obligations
                         finance/event_finances finance/person_finances finance_receipts],
          if: ->(_) { can?(:manage, Finance::Obligation) }
        )
      end

      ### sheets — navigation latérale pour les pages import Excel
      Sheet::Group.include Eeds::Sheet::Group
      Sheet::Person.include Eeds::Sheet::Person

      ### abilities — progression pédagogique
      Ability.store.register Eeds::ProgressionAbility

      ### abilities — MAAS (adhésion annuelle)
      Ability.store.register Maas::MembershipAbility

      ### abilities — Finance (gestion financière des activités)
      Ability.store.register Finance::FinanceAbility
    end

    initializer "hitobito_eeds.add_settings" do |_app|
      Settings.add_source!(File.join(paths["config"].existent, "settings.yml"))
      Settings.reload!
    end

    # Le mécanisme par défaut de Config gem concatène les arrays au lieu de les remplacer.
    # On force l'écrasement des labels prédéfinis pour avoir UNIQUEMENT les libellés EEDS.
    initializer "hitobito_eeds.override_predefined_labels", after: :load_config_initializers do |_app|
      Settings.phone_number.predefined_labels = %w[Domicile GSM Travail Père Mère Fax Autre]
      Settings.social_account.predefined_labels = ["WhatsApp", "Facebook", "Instagram", "Skype", "Site web", "Autre"]
      Settings.additional_address.predefined_labels = %w[Travail Parents Internat]
    end

    private

    def seed_fixtures
      fixtures = root.join("db", "seeds")
      ENV["NO_ENV"] ? [fixtures] : [fixtures, File.join(fixtures, Rails.env)]
    end
  end
end
