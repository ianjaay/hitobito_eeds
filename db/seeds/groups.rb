# encoding: utf-8

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Seeds de la structure officielle des EEDS :
#   - 1 National (racine)
#   - 6 Districts Autonomes (rattachés au National)
#   - 9 Groupes Locaux Autonomes (rattachés au National)
#   - 3 Régions (Dakar, Thiès, Ziguinchor)
#       └ Région de Dakar : 3 districts (Front de Terre, Pikine Guédiawaye, Rufisque)
#
# Idempotent grâce à `seed_once` (gem seed-fu).
RESEED_TIMESTAMP = "2026-04-29"

national = Group::National.seed_once(
  :parent_id,
  {
    name: "Éclaireuses et Éclaireurs du Sénégal",
    short_name: "EEDS",
    parent_id: nil
  }
).first

# --- Districts Autonomes (sous National) ---
districts_autonomes = [
  "District Autonome de Dioffior-Fimela",
  "District Autonome de Diourbel",
  "District Autonome de Kaolack",
  "District Autonome de Kolda",
  "District Autonome de Matam",
  "District Autonome de Saint-Louis"
]

districts_autonomes.each do |name|
  Group::DistrictAutonome.seed_once(
    :parent_id, :name,
    {name: name, parent_id: national.id}
  )
end

# --- Groupes Locaux Autonomes (sous National) ---
groupes_locaux_autonomes = [
  "Groupe Local Autonome Bakel",
  "Groupe Local Autonome Bambey",
  "Groupe Local Autonome Dagana",
  "Groupe Local Autonome Fadiga",
  "Groupe Local Autonome Gossas",
  "Groupe Local Autonome Kaffrine",
  "Groupe Local Autonome Kébémer",
  "Groupe Local Autonome Niakhar",
  "Groupe Local Autonome Tambacounda"
]

groupes_locaux_autonomes.each do |name|
  Group::GroupeLocalAutonome.seed_once(
    :parent_id, :name,
    {name: name, parent_id: national.id}
  )
end

# --- Régions ---
region_dakar = Group::RegionEeds.seed_once(
  :parent_id, :name,
  {name: "Région de Dakar", parent_id: national.id}
).first

Group::RegionEeds.seed_once(
  :parent_id, :name,
  {name: "Région de Thiès", parent_id: national.id}
)

Group::RegionEeds.seed_once(
  :parent_id, :name,
  {name: "Région de Ziguinchor", parent_id: national.id}
)

# --- Districts de la Région de Dakar ---
districts_dakar = [
  "District de Front de Terre",
  "District de Pikine Guédiawaye",
  "District de Rufisque"
]

districts_dakar.each do |name|
  Group::District.seed_once(
    :parent_id, :name,
    {name: name, parent_id: region_dakar.id}
  )
end
