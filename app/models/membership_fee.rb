# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Cotisation annuelle d'un membre EEDS pour une année scoute donnée.
#
# Le montant dépend de la branche (Jiwu, Lawtan, Toor-toor, Meññeef,
# Encadrement) et du tarif national en vigueur pour l'année. Le statut
# évolue de `pending` (générée) → `paid` (encaissée) ou `exempted`
# (dispense accordée). Les cotisations annulées passent à `cancelled`.
class MembershipFee < ApplicationRecord
  self.table_name = "eeds_membership_fees"

  STATUSES = %w[pending paid exempted cancelled].freeze
  PAYMENT_METHODS = %w[cash bank_transfer mobile_money other].freeze
  BRANCHES = %w[jiwu lawtan toor_toor menneef encadrement].freeze

  belongs_to :person
  belongs_to :group
  belongs_to :recorded_by, class_name: "Person", optional: true

  validates :year, presence: true,
    numericality: {only_integer: true, greater_than: 1900, less_than: 3000}
  validates :branche, presence: true, inclusion: {in: BRANCHES}
  validates :amount_cents, presence: true,
    numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :status, presence: true, inclusion: {in: STATUSES}
  validates :payment_method, inclusion: {in: PAYMENT_METHODS}, allow_nil: true
  validates :person_id, uniqueness: {scope: :year}
  validate  :paid_at_required_when_paid

  scope :for_year,    ->(year) { where(year: year) }
  scope :pending,     -> { where(status: "pending") }
  scope :paid,        -> { where(status: "paid") }
  scope :exempted,    -> { where(status: "exempted") }
  scope :cancelled,   -> { where(status: "cancelled") }
  scope :outstanding, -> { where(status: %w[pending]) }

  STATUSES.each do |s|
    define_method(:"#{s}?") { status == s }
  end

  def amount
    amount_cents.to_f / 100
  end

  def mark_paid!(method:, recorded_by:, paid_at: Time.zone.now, reference: nil, comment: nil)
    update!(status: "paid",
      payment_method: method,
      recorded_by: recorded_by,
      paid_at: paid_at,
      reference: reference,
      comment: comment)
  end

  def mark_exempted!(recorded_by:, comment: nil)
    update!(status: "exempted",
      recorded_by: recorded_by,
      paid_at: nil,
      payment_method: nil,
      comment: comment)
  end

  def cancel!(recorded_by:, comment: nil)
    update!(status: "cancelled", recorded_by: recorded_by, comment: comment)
  end

  private

  def paid_at_required_when_paid
    return unless paid?
    return if paid_at.present?

    errors.add(:paid_at, :blank)
  end
end
