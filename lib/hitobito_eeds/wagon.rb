# frozen_string_literal: true

#  Adaptation Hitobito pour les Éclaireuses et Éclaireurs du Sénégal (E-Gàlle).
#  Ce wagon contient les spécificités EEDS qui s'ajoutent par-dessus hitobito_pbs.

module HitobitoEeds
  class Wagon < Rails::Engine
    include Wagons::Wagon

    app_requirement ">= 0"

    config.autoload_paths += %W[
      #{config.root}/app/abilities
      #{config.root}/app/domain
      #{config.root}/app/jobs
      #{config.root}/app/serializers
    ]

    config.to_prepare do
      ### models — extensions EEDS
      Person.include Eeds::Person

      ### controllers — retirer les attributs Suisse-spécifiques exposés par PBS
      # j_s_number = N° Jeunesse+Sport (programme suisse) — sans objet pour EEDS
      PeopleController.permitted_attrs -= [:j_s_number]
      # Ajouter les attributs EEDS aux paramètres autorisés
      PeopleController.permitted_attrs += [
        :birthplace, :nationality, :administrative_region,
        :emergency_contact_name, :emergency_contact_phone, :emergency_contact_relation
      ]

      ### group types — autoriser le sous-groupe sous chaque unité
      # (Mbotaay, Kayon, Ñawka, Gàlle = Woelfe, Pfadi, Pio, Rover en interne PBS)
      [Group::Woelfe, Group::Pfadi, Group::Pio, Group::Rover].each do |unit|
        unit.children(Group::Subgroup) unless unit.possible_children.include?(Group::Subgroup)
      end
      # Invalider les caches de types sans toucher aux root_types
      Group.class_variable_set(:@@all_types, nil) if Group.class_variable_defined?(:@@all_types)
      Role.reset_types!
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
      ENV["NO_ENV"] ? [fixtures] : [fixtures, ENV["RAILS_ENV"]]
    end
  end
end
