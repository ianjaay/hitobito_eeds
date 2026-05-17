# frozen_string_literal: true

# EEDS : layer_and_below_full doit permettre de voir et gérer les listes
# de diffusion dans les couches inférieures (core limite à in_same_layer).
module Eeds::MailingListAbility
  extend ActiveSupport::Concern

  included do
    on(MailingList) do
      permission(:layer_and_below_full)
        .may(:show, :index_subscriptions, :export_subscriptions)
        .in_same_layer_or_below

      permission(:layer_and_below_full)
        .may(:create, :update, :update_subscriptions, :destroy)
        .in_same_layer_or_below_if_active
    end
  end
end
