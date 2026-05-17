# frozen_string_literal: true

class Maas::FinancialDistribution < ApplicationRecord
  self.table_name = "maas_financial_distributions"

  STRUCTURE_TYPES = %w[local district region national].freeze
  STATUTS = %w[calcule credite reverse].freeze

  belongs_to :payment_transaction, class_name: "Maas::PaymentTransaction"
  belongs_to :structure, class_name: "::Group", foreign_key: :structure_id

  validates :structure_type, presence: true, inclusion: { in: STRUCTURE_TYPES }
  validates :pourcentage, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :montant, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :statut, presence: true, inclusion: { in: STATUTS }
end
