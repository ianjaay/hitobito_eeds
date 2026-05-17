# frozen_string_literal: true

# EEDS : layer_and_below_full doit permettre de gérer les calendriers,
# les demandes d'ajout de personnes et les service tokens dans les couches
# inférieures (core limite à in_same_layer).
module Eeds::GroupAbility
  extend ActiveSupport::Concern

  included do
    on(Group) do
      permission(:layer_and_below_full)
        .may(:index_calendars)
        .in_same_layer_or_below

      permission(:layer_and_below_full)
        .may(:activate_person_add_requests, :deactivate_person_add_requests)
        .in_same_layer_or_below_if_active
    end
  end
end
