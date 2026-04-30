# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Habilitations CanCan pour les recensements EEDS.
# Le recensement est consulté/géré par les rôles ayant la permission
# `:layer_and_below_full` ou `:layer_and_below_read` à un niveau couvrant
# le groupe ciblé. La saisie se fait au niveau Groupe Local par les
# rôles de Maîtrise (Chef de Groupe, etc.) qui possèdent
# `:layer_and_below_full` sur leur Groupe Local.
class MemberCountAbility < AbilityDsl::Base
  on(MemberCount) do
    permission(:layer_and_below_full)
      .may(:show, :index, :create, :update, :destroy, :recompute).in_layer_scope
    permission(:layer_full)
      .may(:show, :index, :create, :update, :recompute).in_layer_scope
    permission(:layer_and_below_read)
      .may(:show, :index).in_layer_scope
    permission(:layer_read)
      .may(:show, :index).in_layer_scope
  end

  on(Census) do
    permission(:admin).may(:show, :index, :create, :update, :destroy).all
    permission(:layer_and_below_read).may(:show, :index).all
  end

  def in_layer_scope
    return false unless subject.respond_to?(:group_id) && subject.group_id

    relevant_group_ids.include?(subject.group_id)
  end

  private

  def relevant_group_ids
    @relevant_group_ids ||= begin
      perms = %i[layer_and_below_full layer_and_below_read layer_full layer_read]
      groups = perms.flat_map { |p| user.groups_with_permission(p) }.uniq.map(&:reload)
      groups.flat_map { |g|
        Group.where("lft >= ? AND rgt <= ?", g.lft, g.rgt).pluck(:id)
      }.uniq
    end
  end
end
