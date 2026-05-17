# frozen_string_literal: true

# EEDS : layer_and_below_full doit permettre de créer/supprimer des
# participations dans les couches inférieures (core limite à in_same_layer).
module Eeds::Event::ParticipationAbility
  extend ActiveSupport::Concern

  included do
    on(Event::Participation) do
      permission(:layer_and_below_full)
        .may(:create, :destroy)
        .in_same_layer_or_below
    end
  end
end
