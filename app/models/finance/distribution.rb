# frozen_string_literal: true

# Répartition financière d'un paiement vers les structures hiérarchiques.
class Finance::Distribution < ApplicationRecord
  self.table_name = "finance_distributions"

  STRUCTURE_TYPES = %w[local district region national].freeze
  STATUTS = %w[calcule credite reverse].freeze

  belongs_to :payment, class_name: "Finance::Payment"
  belongs_to :structure, class_name: "::Group", foreign_key: :structure_id

  validates :structure_type, presence: true, inclusion: { in: STRUCTURE_TYPES }
  validates :pourcentage, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :montant, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :statut, presence: true, inclusion: { in: STATUTS }
end
