# frozen_string_literal: true

class Maas::PaymentTransaction < ApplicationRecord
  self.table_name = "maas_payment_transactions"

  MODALITES = %w[Cash Virement Autre].freeze
  STATUTS = %w[enregistre valide annule].freeze

  belongs_to :membership_subscription, class_name: "Maas::MembershipSubscription"
  belongs_to :enregistre_par, class_name: "::Person", foreign_key: :enregistre_par_id

  has_many :financial_distributions, class_name: "Maas::FinancialDistribution",
           foreign_key: :payment_transaction_id, dependent: :destroy
  has_one :receipt, class_name: "Maas::Receipt", foreign_key: :payment_transaction_id, dependent: :nullify

  validates :modalite, presence: true, inclusion: { in: MODALITES }
  validates :montant, presence: true, numericality: { greater_than: 0 }
  validates :statut, presence: true, inclusion: { in: STATUTS }
  validate :montant_above_minimum_partiel, on: :create
  validate :subscription_not_fully_paid, on: :create

  after_create :update_subscription_totals
  after_create :set_valide_at
  after_create :generate_receipt

  scope :valides, -> { where(statut: %w[enregistre valide]) }

  private

  def montant_above_minimum_partiel
    min = membership_subscription&.membership_plan&.minimum_partiel
    return unless min && montant

    if montant < min && membership_subscription.montant_paye.zero?
      errors.add(:montant, "doit être au minimum #{min.to_i} FCFA pour un premier versement")
    end
  end

  def subscription_not_fully_paid
    return unless membership_subscription&.fully_paid?

    errors.add(:base, "Cette adhésion est déjà intégralement payée")
  end

  def update_subscription_totals
    membership_subscription.recalculate_montant_paye!
  end

  def set_valide_at
    update_columns(valide_at: Time.current)
  end

  def generate_receipt
    Maas::ReceiptService.create_for_payment!(self)
  rescue => e
    Rails.logger.error("Cotisations: Erreur génération reçu pour transaction #{id}: #{e.message}")
  end
end
