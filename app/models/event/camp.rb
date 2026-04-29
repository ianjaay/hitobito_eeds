# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Camp EEDS — sous-classe STI de Event.
#
# Inspirée du Camp PBS mais simplifiée : pas de J+S, pas de BSV, pas de
# kantonalverband. Le workflow d'approbation suit la chaîne EEDS :
# Groupe Local → District → Région → National (chaque niveau peut être
# court-circuité pour les structures autonomes).
class Event::Camp < Event
  # Attributs additionnels exposés dans les formulaires.
  self.used_attributes += [
    :expected_participants_jiwu_f, :expected_participants_jiwu_m,
    :expected_participants_lawtan_f, :expected_participants_lawtan_m,
    :expected_participants_toor_toor_f, :expected_participants_toor_toor_m,
    :expected_participants_menneef_f, :expected_participants_menneef_m,
    :expected_participants_encadrement_f, :expected_participants_encadrement_m,
    :camp_location, :camp_address, :camp_coordinates,
    :camp_emergency_phone, :camp_owner,
    :camp_submitted, :parental_authorizations_collected,
    :assurance_validated, :camp_days_count_validated_on,
    :requires_approval_groupe_local, :requires_approval_district,
    :requires_approval_region, :requires_approval_national
  ]

  # Liste ordonnée des branches EEDS pour l'affichage des effectifs attendus.
  EXPECTED_PARTICIPANT_BRANCHES = %w[jiwu lawtan toor_toor menneef encadrement].freeze

  # Niveaux possibles d'approbation, dans l'ordre de remontée hiérarchique.
  APPROVAL_LAYERS = %w[groupe_local district region national].freeze

  ### CLASS METHODS

  class << self
    def expected_participant_attrs
      EXPECTED_PARTICIPANT_BRANCHES.flat_map do |b|
        [:"expected_participants_#{b}_f", :"expected_participants_#{b}_m"]
      end
    end
  end

  ### INSTANCE

  def total_expected_participants
    self.class.expected_participant_attrs.sum { |attr| send(attr).to_i }
  end

  def required_approval_layers
    APPROVAL_LAYERS.select { |l| public_send(:"requires_approval_#{l}?") }
  end
end
