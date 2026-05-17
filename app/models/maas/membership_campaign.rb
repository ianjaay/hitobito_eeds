# frozen_string_literal: true

class Maas::MembershipCampaign < ApplicationRecord
  self.table_name = "maas_membership_campaigns"

  STATUTS = %w[brouillon active fermee archivee].freeze

  belongs_to :created_by, class_name: "::Person", optional: true
  has_many :membership_plans, class_name: "Maas::MembershipPlan",
           foreign_key: :membership_campaign_id, dependent: :destroy
  has_many :membership_subscriptions, class_name: "Maas::MembershipSubscription",
           foreign_key: :membership_campaign_id, dependent: :restrict_with_error

  validates :annee, presence: true, uniqueness: true,
            format: { with: /\A\d{4}\z/, message: "doit être une année sur 4 chiffres" }
  validates :date_ouverture, presence: true
  validates :date_fermeture, presence: true
  validates :statut, presence: true, inclusion: { in: STATUTS }
  validate :date_fermeture_after_ouverture

  scope :active, -> { where(statut: "active") }
  scope :visible, -> { where(statut: %w[active fermee]) }
  scope :by_year, ->(year) { where(annee: year.to_s) }

  def active?
    statut == "active"
  end

  def ouverte?
    active? && date_ouverture <= Time.current && date_fermeture >= Time.current
  end

  def total_collected
    membership_subscriptions.sum(:montant_paye)
  end

  def total_members
    membership_subscriptions.where(statut: %w[partiel valide]).count
  end

  private

  def date_fermeture_after_ouverture
    return if date_ouverture.blank? || date_fermeture.blank?

    if date_fermeture <= date_ouverture
      errors.add(:date_fermeture, "doit être postérieure à la date d'ouverture")
    end
  end
end
