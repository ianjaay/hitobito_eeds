# frozen_string_literal: true
#!/usr/bin/env rake

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

begin
  require "bundler/setup"
rescue LoadError
  puts "You must `gem install bundler` and `bundle install` to run rake tasks"
end

ENGINE_PATH = File.expand_path("..", __FILE__)
load File.expand_path("../app_root.rb", __FILE__)

load "wagons/wagon_tasks.rake"

load "rspec/rails/tasks/rspec.rake"

require "ci/reporter/rake/rspec" unless Rails.env == "production"

HitobitoEeds::Wagon.load_tasks
