# frozen_string_literal: true

# Versement/paiement effectué sur une obligation financière.
class Finance::Payment < ApplicationRecord
  self.table_name = "finance_payments"

  MODALITES = %w[Cash Virement Mobile Autre].freeze
  STATUTS = %w[enregistre valide annule].freeze

  belongs_to :obligation, class_name: "Finance::Obligation"
  belongs_to :enregistre_par, class_name: "::Person", foreign_key: :enregistre_par_id

  has_many :distributions, class_name: "Finance::Distribution",
           foreign_key: :payment_id, dependent: :destroy
  has_one :receipt, class_name: "Finance::Receipt",
          foreign_key: :payment_id, dependent: :nullify

  validates :modalite, presence: true, inclusion: { in: MODALITES }
  validates :montant, presence: true, numericality: { greater_than: 0 }
  validates :statut, presence: true, inclusion: { in: STATUTS }
  validate :montant_above_minimum_partiel, on: :create
  validate :obligation_not_fully_paid, on: :create

  after_create :update_obligation_totals
  after_create :set_valide_at
  after_create :generate_receipt

  scope :valides, -> { where(statut: %w[enregistre valide]) }

  private

  def montant_above_minimum_partiel
    min = obligation&.activity_fee&.minimum_partiel
    return unless min && montant

    if montant < min && obligation.montant_paye.zero?
      errors.add(:montant, "doit être au minimum #{min.to_i} FCFA pour un premier versement")
    end
  end

  def obligation_not_fully_paid
    return unless obligation&.fully_paid?

    errors.add(:base, "Cette obligation est déjà intégralement payée")
  end

  def update_obligation_totals
    obligation.recalculate_montant_paye!
  end

  def set_valide_at
    update_columns(valide_at: Time.current)
  end

  def generate_receipt
    Finance::ReceiptService.create_for_payment!(self)
  rescue => e
    Rails.logger.error("Finance: Erreur génération reçu pour paiement #{id}: #{e.message}")
  end
end
