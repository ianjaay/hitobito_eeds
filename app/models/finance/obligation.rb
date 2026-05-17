# frozen_string_literal: true

# Obligation de paiement d'un participant pour un frais donné.
# Relie une personne à un Finance::ActivityFee avec suivi du montant payé.
class Finance::Obligation < ApplicationRecord
  self.table_name = "finance_obligations"

  STATUTS = %w[en_attente partiel valide expire annule].freeze
  STATUTS_ACTIFS = %w[en_attente partiel valide].freeze

  belongs_to :activity_fee, class_name: "Finance::ActivityFee"
  belongs_to :person, class_name: "::Person"
  belongs_to :group, class_name: "::Group"

  # Lien optionnel vers la participation event (camps, formations, etc.)
  belongs_to :event_participation, class_name: "::Event::Participation", optional: true

  # Lien optionnel vers l'adhésion MAAS (rétrocompatibilité)
  belongs_to :membership_subscription, class_name: "Maas::MembershipSubscription", optional: true

  has_many :payments, class_name: "Finance::Payment",
           foreign_key: :obligation_id, dependent: :restrict_with_error
  has_many :receipts, class_name: "Finance::Receipt",
           foreign_key: :obligation_id, dependent: :restrict_with_error

  validates :statut, presence: true, inclusion: { in: STATUTS }
  validates :montant_total, presence: true, numericality: { greater_than: 0 }
  validates :montant_paye, numericality: { greater_than_or_equal_to: 0 }
  validates :activity_fee_id, uniqueness: { scope: :person_id,
                                            message: "a déjà une obligation pour ce frais" }

  scope :actives, -> { where(statut: STATUTS_ACTIFS) }
  scope :avec_solde, -> { where("finance_obligations.montant_total > finance_obligations.montant_paye") }
  scope :for_group, ->(group_id) { where(group_id: group_id) }
  scope :for_person, ->(person_id) { where(person_id: person_id) }
  scope :for_event, -> { joins(:activity_fee).where(finance_activity_fees: { feeable_type: "Event" }) }
  scope :for_campaign, -> { joins(:activity_fee).where(finance_activity_fees: { feeable_type: "Maas::MembershipCampaign" }) }

  before_validation :set_montant_from_fee, on: :create
  after_save :update_statut_from_payments, if: :saved_change_to_montant_paye?

  def solde_restant
    [montant_total - montant_paye, 0].max
  end

  def fully_paid?
    montant_paye >= montant_total
  end

  def recalculate_montant_paye!
    total = payments.where(statut: %w[enregistre valide]).sum(:montant)
    update_columns(montant_paye: total)
    update_statut_from_payments
  end

  def activite_nom
    activity_fee&.feeable&.try(:name) || activity_fee&.feeable&.try(:annee) || activity_fee&.libelle
  end

  private

  def set_montant_from_fee
    self.montant_total ||= activity_fee&.montant
  end

  def update_statut_from_payments
    new_statut = if montant_paye >= montant_total
                   "valide"
                 elsif montant_paye > 0
                   "partiel"
                 else
                   statut
                 end

    if new_statut != statut
      update_columns(statut: new_statut)
      if new_statut == "valide" && activity_fee&.montant_assurance&.positive?
        update_columns(assurance_active: true)
      end
    end
  end
end
