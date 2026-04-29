# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

module HitobitoEeds
  class Wagon < Rails::Engine
    include Wagons::Wagon

    # Required hitobito core version.
    app_requirement ">= 0"

    # Additional autoload paths for this wagon.
    config.autoload_paths += %W[
      #{config.root}/app/abilities
      #{config.root}/app/domain
      #{config.root}/app/jobs
      #{config.root}/app/serializers
    ]

    # Models / controllers / decorators / mailers extension points.
    #
    # Concerns and group/role types are added in subsequent Phase 1 todos
    # (p1-group-*, p1-root-types). Each `Group::*` STI subclass declared in
    # app/models/group/ is autoloaded by Rails — no explicit require needed
    # here, but root-level types must still be registered:
    #
    #   Group.root_types Group::National
    #
    # When Person/Group concerns appear (Phase 2), wire them up as:
    #
    #   Group.include  Eeds::Group
    #   Person.include Eeds::Person
    #   Role.include   Eeds::Role
    config.to_prepare do
      # Register Group::National as the root type of the EEDS hierarchy.
      # This makes it the only group that can be created without a parent.
      Group.root_types Group::National

      # Extend Person with EEDS-specific fields (matricule_scout, branche,
      # parent contact, etc.).
      Person.include Eeds::Person

      # Force-load the EEDS Camp STI subclass so that Event#types collects it
      # for use by Group#event_types and the type selector.
      Event::Camp
    end

    # We can't directly override the languages hash in a config file since
    # Settings hashes are merged. Force-replace the languages hash so that
    # only EEDS languages (fr, wo) are exposed in the UI.
    config.to_prepare do
      settings = Settings.to_hash
      settings[:application][:languages] = {fr: "Français", wo: "Wolof"}
      Settings.reload_from_files(settings)
    end

    initializer "hitobito_eeds.add_settings" do |_app|
      Settings.add_source!(File.join(paths["config"].existent, "settings.yml"))
      Settings.reload!
    end

    private

    def seed_fixtures
      fixtures = root.join("db", "seeds")
      ENV["NO_ENV"] ? [fixtures] : [fixtures, File.join(fixtures, Rails.env)]
    end
  end
end
