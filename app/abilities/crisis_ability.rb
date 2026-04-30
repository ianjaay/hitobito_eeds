# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Habilitations CanCan pour les crises EEDS.
# - `:approve_applications` (Chef Groupe, Commissaires) ⇒ peut créer une
#   crise sur son propre groupe ou sa hiérarchie.
# - `:layer_and_below_full` au-dessus du Groupe Local ⇒ peut acquitter et
#   clôturer (Commissaire de District, Régional, National).
class CrisisAbility < AbilityDsl::Base
  on(Crisis) do
    permission(:approve_applications)
      .may(:show, :index, :create).in_layer_scope

    permission(:layer_and_below_full)
      .may(:show, :index, :create, :update, :acknowledge, :complete, :destroy).in_layer_scope

    permission(:layer_and_below_read)
      .may(:show, :index).in_layer_scope
  end

  def in_layer_scope
    return false unless subject.respond_to?(:group_id) && subject.group_id

    relevant_group_ids.include?(subject.group_id)
  end

  private

  def relevant_group_ids
    @relevant_group_ids ||= begin
      perms = %i[approve_applications layer_and_below_full layer_and_below_read]
      groups = perms.flat_map { |p| user.groups_with_permission(p) }.uniq.map(&:reload)
      groups.flat_map { |g|
        Group.where("lft >= ? AND rgt <= ?", g.lft, g.rgt).pluck(:id)
      }.uniq
    end
  end
end
