# frozen_string_literal: true

# EEDS : layer_and_below_full doit permettre de gérer les calendriers
# dans les couches inférieures (core limite à in_same_layer).
module Eeds::CalendarAbility
  extend ActiveSupport::Concern

  included do
    on(Calendar) do
      permission(:layer_and_below_full)
        .may(:manage)
        .in_same_layer_or_below
    end
  end

  def in_same_layer_or_below
    layer_ids = user.groups.map(&:layer_group_id)
    target_layer = subject.group.layer_group
    layer_ids.include?(target_layer.id) ||
      target_layer.ancestors.any? { |a| layer_ids.include?(a.id) }
  end
end
