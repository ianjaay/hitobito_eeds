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
    end

    initializer "hitobito_eeds.add_settings" do |_app|
      # Place pour overrider les Settings (labels téléphone/social etc.)
    end

    private

    def seed_fixtures
      fixtures = root.join("db", "seeds")
      ENV["NO_ENV"] ? [fixtures] : [fixtures, ENV["RAILS_ENV"]]
    end
  end
end
