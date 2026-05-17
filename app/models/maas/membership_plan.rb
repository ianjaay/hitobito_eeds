# frozen_string_literal: true

class Maas::MembershipPlan < ApplicationRecord
  self.table_name = "maas_membership_plans"

  BRANCHES = %w[Mbootaay Kayon Dental Galle National Gilwell].freeze

  belongs_to :membership_campaign, class_name: "Maas::MembershipCampaign"
  has_many :membership_subscriptions, class_name: "Maas::MembershipSubscription",
           foreign_key: :membership_plan_id, dependent: :restrict_with_error

  validates :branche, presence: true, inclusion: { in: BRANCHES }
  validates :montant, presence: true, numericality: { greater_than: 0 }
  validates :montant_assurance, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :minimum_partiel, numericality: { greater_than: 0 }, allow_nil: true
  validates :branche, uniqueness: { scope: :membership_campaign_id,
                                    message: "existe déjà pour cette campagne" }

  def label
    "#{branche} — #{montant.to_i} FCFA"
  end
end
