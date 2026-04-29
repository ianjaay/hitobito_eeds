# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Construit la chaîne d'approbation requise pour une candidature à un camp,
# en partant du `primary_group` (ou du `group` du camp) et en remontant
# l'arbre EEDS.
#
# Règles :
#   - Régulier : groupe_local → district → region → national
#   - District Autonome  : district → national
#   - Groupe Local Autonome : groupe_local → national
class Eeds::ApprovalChain
  LAYER_FOR_CLASS = {
    "Group::GroupeLocal"          => "groupe_local",
    "Group::GroupeLocalAutonome"  => "groupe_local",
    "Group::District"             => "district",
    "Group::DistrictAutonome"     => "district",
    "Group::RegionEeds"           => "region",
    "Group::National"             => "national"
  }.freeze

  AUTONOMOUS_PARENTS = %w[Group::DistrictAutonome Group::GroupeLocalAutonome].freeze

  def initialize(group)
    @group = group
  end

  # Liste ordonnée (du plus local au plus haut) des couches qui doivent
  # approuver. Inclut toujours national en bout de chaîne.
  def layers
    chain = []
    cursor = @group

    while cursor
      mapped = LAYER_FOR_CLASS[cursor.class.name]
      chain << mapped if mapped && !chain.include?(mapped)

      # Court-circuit : une structure autonome saute directement au National.
      if AUTONOMOUS_PARENTS.include?(cursor.class.name)
        chain << "national" unless chain.include?("national")
        break
      end

      cursor = cursor.parent
    end

    chain.uniq
  end
end
