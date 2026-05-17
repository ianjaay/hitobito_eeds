# frozen_string_literal: true

# Service de création de reçus pour les paiements Finance.
class Finance::ReceiptService
  def self.create_for_payment!(payment)
    obligation = payment.obligation
    fee = obligation.activity_fee
    person = obligation.person

    Finance::Receipt.create!(
      payment: payment,
      obligation: obligation,
      person: person,
      montant: payment.montant,
      libelle_activite: fee.libelle,
      modalite: payment.modalite,
      groupe_nom: obligation.group&.name,
      annee: Date.current.year,
      emis_at: Time.current
    )
  end
end
