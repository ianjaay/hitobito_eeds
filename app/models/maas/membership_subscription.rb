# frozen_string_literal: true

class Maas::MembershipSubscription < ApplicationRecord
  self.table_name = "maas_membership_subscriptions"

  STATUTS = %w[en_attente partiel valide expire annule].freeze
  STATUTS_ACTIFS = %w[partiel valide].freeze

  belongs_to :membership_campaign, class_name: "Maas::MembershipCampaign"
  belongs_to :membership_plan, class_name: "Maas::MembershipPlan"
  belongs_to :member, class_name: "::Person"
  belongs_to :group, class_name: "::Group"

  has_many :payment_transactions, class_name: "Maas::PaymentTransaction",
           foreign_key: :membership_subscription_id, dependent: :restrict_with_error
  has_many :receipts, class_name: "Maas::Receipt",
           foreign_key: :membership_subscription_id, dependent: :restrict_with_error

  validates :statut, presence: true, inclusion: { in: STATUTS }
  validates :montant_total, presence: true, numericality: { greater_than: 0 }
  validates :montant_paye, numericality: { greater_than_or_equal_to: 0 }
  validates :member_id, uniqueness: { scope: :membership_campaign_id,
                                      message: "a déjà une adhésion pour cette campagne" }

  scope :actives, -> { where(statut: STATUTS_ACTIFS) }
  scope :avec_solde, -> { where("maas_membership_subscriptions.montant_total > maas_membership_subscriptions.montant_paye") }
  scope :for_group, ->(group_id) { where(group_id: group_id) }
  scope :for_campaign, ->(campaign_id) { where(membership_campaign_id: campaign_id) }

  before_validation :set_montant_from_plan, on: :create
  before_validation :set_expires_at, on: :create
  after_save :update_statut_from_payments, if: :saved_change_to_montant_paye?

  def solde_restant
    [montant_total - montant_paye, 0].max
  end

  def fully_paid?
    montant_paye >= montant_total
  end

  def recalculate_montant_paye!
    total = payment_transactions.where(statut: %w[enregistre valide]).sum(:montant)
    update_columns(montant_paye: total)
    update_statut_from_payments
  end

  private

  def set_montant_from_plan
    self.montant_total ||= membership_plan&.montant
  end

  def set_expires_at
    self.expires_at ||= Date.new(membership_campaign.annee.to_i, 12, 31).end_of_day if membership_campaign&.annee
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
      if new_statut == "valide" && membership_plan&.assurance_incluse?
        update_columns(assurance_active: true)
      end
    end
  end
end
