# frozen_string_literal: true

# Autorisations pour le module Financier générique.
#
# - Les administrateurs (layer_and_below_full, admin) gèrent tout
# - Les responsables locaux (group_full) gèrent les finances de leur groupe
# - Les responsables de sous-groupes gèrent leurs sous-groupes
class Finance::FinanceAbility < AbilityDsl::Base
  # ── Frais d'activité ──
  on(Finance::ActivityFee) do
    permission(:layer_and_below_full).may(:manage).all
    permission(:admin).may(:manage).all
    permission(:group_full).may(:read, :create, :update).in_same_group
    permission(:group_and_below_full).may(:read, :create, :update).in_same_group_or_below
  end

  # ── Obligations ──
  on(Finance::Obligation) do
    permission(:layer_and_below_full).may(:manage).all
    permission(:admin).may(:manage).all
    permission(:group_full).may(:read, :create, :update).in_same_group
    permission(:group_and_below_full).may(:read, :create, :update).in_same_group_or_below
  end

  # ── Paiements ──
  on(Finance::Payment) do
    permission(:layer_and_below_full).may(:manage).all
    permission(:admin).may(:manage).all
    permission(:group_full).may(:read, :create).if_obligation_in_group
  end

  # ── Reçus ──
  on(Finance::Receipt) do
    permission(:layer_and_below_full).may(:read).all
    permission(:admin).may(:read).all
    permission(:group_full).may(:read).if_obligation_in_group
  end

  def in_same_group
    permission_in_groups?(subject.group_id)
  end

  def in_same_group_or_below
    permission_in_groups?(subject.group.self_and_descendants.pluck(:id))
  end

  def if_obligation_in_group
    obligation = subject.respond_to?(:obligation) ? subject.obligation : subject
    permission_in_groups?(obligation.group_id)
  end
end
