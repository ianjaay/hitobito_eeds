# frozen_string_literal: true

# Reçu de paiement (générateur de PDF).
class Finance::Receipt < ApplicationRecord
  self.table_name = "finance_receipts"

  belongs_to :payment, class_name: "Finance::Payment"
  belongs_to :obligation, class_name: "Finance::Obligation"
  belongs_to :person, class_name: "::Person"

  validates :numero, presence: true, uniqueness: true
  validates :montant, presence: true, numericality: { greater_than: 0 }
  validates :emis_at, presence: true

  scope :for_person, ->(person_id) { where(person_id: person_id) }
  scope :recent_first, -> { order(emis_at: :desc) }

  before_validation :generate_numero, on: :create
  before_validation :set_emis_at, on: :create

  def pdf_filename
    "recu_#{numero}.pdf"
  end

  private

  def generate_numero
    return if numero.present?

    year = annee || Time.current.year
    seq = (self.class.where("numero LIKE ?", "FIN-#{year}-%").count + 1)
    self.numero = format("FIN-%04d-%05d", year, seq)
  end

  def set_emis_at
    self.emis_at ||= Time.current
  end
end
