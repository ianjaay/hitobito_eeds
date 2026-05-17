# frozen_string_literal: true

# EEDS : layer_and_below_full doit donner accès aux couches inférieures,
# pas seulement à la même couche.
module Eeds::EventAbility
  extend ActiveSupport::Concern

  included do
    on(Event) do
      permission(:layer_and_below_full)
        .may(:qualifications_read)
        .in_same_layer_or_below
    end
  end
end
