# frozen_string_literal: true

# Crée automatiquement un reçu (Maas::Receipt) après chaque paiement enregistré.
module Maas
  class ReceiptService
    def self.create_for_payment!(transaction)
      subscription = transaction.membership_subscription
      plan = subscription.membership_plan
      campaign = subscription.membership_campaign

      Maas::Receipt.create!(
        membership_subscription: subscription,
        payment_transaction: transaction,
        member: subscription.member,
        montant: transaction.montant,
        modalite: transaction.modalite,
        branche: plan&.branche,
        annee_campagne: campaign.annee.to_i,
        groupe_nom: subscription.group&.name
      )
    end
  end
end
