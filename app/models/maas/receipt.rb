# frozen_string_literal: true

class Maas::Receipt < ApplicationRecord
  self.table_name = "maas_receipts"

  belongs_to :membership_subscription, class_name: "Maas::MembershipSubscription"
  belongs_to :payment_transaction, class_name: "Maas::PaymentTransaction"
  belongs_to :member, class_name: "::Person"

  validates :numero, presence: true, uniqueness: true
  validates :montant, presence: true, numericality: { greater_than: 0 }
  validates :emis_at, presence: true

  scope :for_member, ->(person_id) { where(member_id: person_id) }
  scope :recent_first, -> { order(emis_at: :desc) }

  before_validation :generate_numero, on: :create
  before_validation :set_emis_at, on: :create

  def pdf_filename
    "recu_maas_#{numero}.pdf"
  end

  private

  def generate_numero
    return if numero.present?

    year = annee_campagne || Time.current.year
    seq = (self.class.where("numero LIKE ?", "COT-#{year}-%").count + 1)
    self.numero = format("COT-%04d-%05d", year, seq)
  end

  def set_emis_at
    self.emis_at ||= Time.current
  end
end
