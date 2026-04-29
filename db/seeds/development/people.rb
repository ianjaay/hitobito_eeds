# encoding: utf-8

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Seed d'un super-admin pour le développement local.
# Ce fichier vit sous db/seeds/development/ et n'est chargé par seed-fu qu'en
# environnement dev (HitobitoEeds::Wagon#seed_fixtures inclut db/seeds/<env>).
# La garde Rails.env.development? est une double sécurité.

return unless Rails.env.development?

national = Group::National.first
return unless national

person = Person.seed_once(
  :email,
  {
    first_name: "Admin",
    last_name: "EEDS",
    email: "admin@eeds.local",
    password: "admin@eeds.local",
    password_confirmation: "admin@eeds.local"
  }
).first

# Idempotent : si le rôle existe déjà sur ce groupe, ne pas le recréer.
unless Role.exists?(person_id: person.id,
                    group_id: national.id,
                    type: Group::National::President.sti_name)
  Group::National::President.create!(person: person, group: national)
end
