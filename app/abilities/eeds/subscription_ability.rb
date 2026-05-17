# frozen_string_literal: true

# EEDS : layer_and_below_full doit permettre de gérer les abonnements
# dans les couches inférieures (core limite à in_same_layer).
module Eeds::SubscriptionAbility
  extend ActiveSupport::Concern

  included do
    on(Subscription) do
      permission(:layer_and_below_full)
        .may(:manage)
        .in_same_layer_or_below
    end
  end
end
