# frozen_string_literal: true

# Orchestre la création d'une adhésion + premier versement.
# Appelé par le controller responsable local.
module Maas
  class AdhesionService
    attr_reader :subscription, :transaction, :errors

    def initialize(campaign:, plan:, member:, group:, enregistre_par:)
      @campaign = campaign
      @plan = plan
      @member = member
      @group = group
      @enregistre_par = enregistre_par
      @errors = []
    end

    # Crée la subscription et optionnellement le premier versement
    # Returns true/false
    def create_subscription!(montant: nil, modalite: "Cash", reference: nil, notes: nil)
      ActiveRecord::Base.transaction do
        @subscription = Maas::MembershipSubscription.create!(
          membership_campaign: @campaign,
          membership_plan: @plan,
          member: @member,
          group: @group,
          montant_total: @plan.montant,
          statut: "en_attente"
        )

        if montant.present? && montant.to_d > 0
          @transaction = record_payment!(
            montant: montant,
            modalite: modalite,
            reference: reference,
            notes: notes
          )
        end

        true
      end
    rescue ActiveRecord::RecordInvalid => e
      @errors << e.message
      false
    end

    # Enregistre un versement sur une subscription existante
    def record_payment!(montant:, modalite: "Cash", reference: nil, notes: nil)
      tx = Maas::PaymentTransaction.create!(
        membership_subscription: @subscription || raise(ArgumentError, "No subscription"),
        modalite: modalite,
        montant: montant.to_d,
        reference_manuelle: reference,
        notes: notes,
        enregistre_par: @enregistre_par
      )

      # Calculer les distributions financières
      Maas::DistributionService.new(transaction: tx).distribute!

      tx
    end
  end
end
