# frozen_string_literal: true

# Autorisations pour le Module d'Adhésion Annuelle Solidaire (MAAS).
#
# - Les administrateurs (layer_and_below_full) gèrent les campagnes et plans
# - Les responsables locaux (group_full) gèrent les adhésions de leur groupe
class Maas::MembershipAbility < AbilityDsl::Base
  # ── Campagnes (admin national) ──
  on(Maas::MembershipCampaign) do
    permission(:layer_and_below_full).may(:manage).all
    permission(:admin).may(:manage).all
  end

  # ── Subscriptions (responsable local) ──
  on(Maas::MembershipSubscription) do
    permission(:layer_and_below_full).may(:manage).all
    permission(:admin).may(:manage).all
    permission(:group_full).may(:read, :create, :update).in_same_group
    permission(:group_and_below_full).may(:read, :create, :update).in_same_group_or_below
  end

  # ── Transactions (responsable local) ──
  on(Maas::PaymentTransaction) do
    permission(:layer_and_below_full).may(:manage).all
    permission(:admin).may(:manage).all
    permission(:group_full).may(:read, :create).if_subscription_in_group
  end

  def in_same_group
    permission_in_groups?(subject.group_id)
  end

  def in_same_group_or_below
    permission_in_groups?(subject.group.self_and_descendants.pluck(:id))
  end

  def if_subscription_in_group
    permission_in_groups?(subject.membership_subscription.group_id)
  end
end
