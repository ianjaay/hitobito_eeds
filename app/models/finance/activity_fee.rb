# frozen_string_literal: true

# Frais associé à une activité (event, camp, formation, adhésion, etc.)
# Polymorphe : peut être lié à un Event ou une Maas::MembershipCampaign.
class Finance::ActivityFee < ApplicationRecord
  self.table_name = "finance_activity_fees"

  CATEGORIES = %w[inscription transport uniforme cotisation materiel hebergement autre].freeze

  belongs_to :feeable, polymorphic: true  # Event | Maas::MembershipCampaign
  belongs_to :group, class_name: "::Group"

  has_many :obligations, class_name: "Finance::Obligation",
           foreign_key: :activity_fee_id, dependent: :restrict_with_error

  validates :libelle, presence: true
  validates :categorie, presence: true, inclusion: { in: CATEGORIES }
  validates :montant, presence: true, numericality: { greater_than: 0 }
  validates :montant_assurance, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :minimum_partiel, numericality: { greater_than: 0 }, allow_nil: true

  scope :actifs, -> { where(actif: true) }
  scope :obligatoires, -> { where(obligatoire: true) }
  scope :for_event, ->(event) { where(feeable_type: "Event", feeable_id: event.id) }
  scope :for_campaign, ->(campaign) { where(feeable_type: "Maas::MembershipCampaign", feeable_id: campaign.id) }
  scope :by_categorie, ->(cat) { where(categorie: cat) }

  def event?
    feeable_type == "Event"
  end

  def campaign?
    feeable_type == "Maas::MembershipCampaign"
  end

  def label
    "#{libelle} — #{montant.to_i} FCFA"
  end

  def total_attendu
    obligations.sum(:montant_total)
  end

  def total_collecte
    obligations.sum(:montant_paye)
  end
end
