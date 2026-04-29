$LOAD_PATH.push File.expand_path("../lib", __FILE__)

# Maintain your wagon's version:
require "hitobito_eeds/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name = "hitobito_eeds"
  s.version = HitobitoEeds::VERSION
  s.authors = ["EEDS"]
  s.email = ["dev@eeds.sn"]
  s.summary = "Éclaireuses et Éclaireurs du Sénégal organization specific features"
  s.description = "Hitobito wagon defining the organization hierarchy, groups and " \
                  "roles of the Éclaireuses et Éclaireurs du Sénégal (EEDS)."
  s.license = "AGPL-3.0"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile"]

  # Standalone wagon: depends only on hitobito core.
end
