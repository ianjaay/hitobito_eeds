# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Habilitations CanCan pour les cotisations EEDS.
#
# La permission de gestion repose sur `:finance`, déjà portée par les
# rôles Trésorier (Local, District, Régional, National). Le scope d'action
# est défini par la position hiérarchique du rôle :
#   - finance + layer_and_below_full   → couche et descendants
#   - finance + layer_and_below_read   → couche et descendants
#   - finance + group_full              → propre groupe seulement
class MembershipFeeAbility < AbilityDsl::Base
  on(MembershipFee) do
    permission(:finance).may(:show, :index, :create, :update, :destroy,
      :mark_paid, :mark_exempted, :cancel, :generate, :remind, :record_payment).in_finance_scope
    permission(:admin).may(:show, :index, :create, :update, :destroy,
      :mark_paid, :mark_exempted, :cancel, :generate, :remind, :record_payment).all
  end

  def in_finance_scope
    return false unless subject.group_id

    descendant_finance_group_ids.include?(subject.group_id)
  end

  private

  # Tous les ids de groupes couverts par les permissions :finance
  # de l'utilisateur (groupe direct + descendants dans la hiérarchie nested-set).
  def descendant_finance_group_ids
    @descendant_finance_group_ids ||= begin
      finance_groups = user.groups_with_permission(:finance).map(&:reload)
      finance_groups.flat_map { |g|
        Group.where("lft >= ? AND rgt <= ?", g.lft, g.rgt).pluck(:id)
      }.uniq
    end
  end
end
