#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

ENV["RAILS_STRUCTURED_ADDRESSES"] = "1"
ENV["RAILS_ADDRESS_MIGRATION"] = "0"

load File.expand_path("../app_root.rb", __dir__)
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require File.join(ENV.fetch("APP_ROOT", nil), "spec", "spec_helper.rb")

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[HitobitoEeds::Wagon.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  config.fixture_paths = [File.expand_path("../fixtures", __FILE__)]
end
