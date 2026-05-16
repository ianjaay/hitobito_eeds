$LOAD_PATH.push File.expand_path("../lib", __FILE__)

require "hitobito_eeds/version"

Gem::Specification.new do |s|
  s.name = "hitobito_eeds"
  s.version = HitobitoEeds::VERSION
  s.authors = ["EEDS - Éclaireuses et Éclaireurs du Sénégal"]
  s.email = ["contact@eeds.sn"]
  s.summary = "E-GALLE - EEDS"
  s.description = "Plateforme de Gestion des Membres pour les Éclaireuses et Éclaireurs du Sénégal (E-Gàlle)"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile"]

  s.add_dependency "hitobito_pbs"
end
