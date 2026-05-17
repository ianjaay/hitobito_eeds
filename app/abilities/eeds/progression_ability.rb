# frozen_string_literal: true

# Autorisations pour les progressions pédagogiques EEDS.
# Les responsables (layer_full / layer_and_below_full) de la couche
# du groupe peuvent voir et gérer les progressions.
class Eeds::ProgressionAbility < AbilityDsl::Base
  on(Eeds::Progression) do
    permission(:layer_full).may(:index, :show).in_same_layer
    permission(:layer_full).may(:update, :validate_progression, :request_rework, :start).in_same_layer

    permission(:layer_and_below_full).may(:index, :show).in_same_layer_or_below
    permission(:layer_and_below_full).may(:update, :validate_progression, :request_rework, :start).in_same_layer_or_below

    permission(:group_full).may(:index, :show).in_same_group
    permission(:group_full).may(:update, :validate_progression, :request_rework, :start).in_same_group

    permission(:group_and_below_full).may(:index, :show).in_same_group_or_below
    permission(:group_and_below_full).may(:update, :validate_progression, :request_rework, :start).in_same_group_or_below
  end

  def in_same_layer
    permission_in_layer?(subject.group.layer_group_id)
  end

  def in_same_layer_or_below
    permission_in_layers?(subject.person.groups_hierarchy_ids)
  end

  def in_same_group
    permission_in_groups?(subject.group_id)
  end

  def in_same_group_or_below
    permission_in_groups?(subject.person.group_ids)
  end
end
