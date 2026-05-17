# frozen_string_literal: true

# Portefeuille financier par structure (solde cumulé par groupe).
class Finance::Wallet < ApplicationRecord
  self.table_name = "finance_wallets"

  STRUCTURE_TYPES = %w[local district region national].freeze

  belongs_to :structure, class_name: "::Group", foreign_key: :structure_id

  validates :structure_type, presence: true, inclusion: { in: STRUCTURE_TYPES }
  validates :structure_id, uniqueness: { scope: :structure_type }

  scope :for_structure, ->(group_id) { where(structure_id: group_id) }

  def credit!(amount)
    with_lock do
      self.balance += amount
      self.total_collected += amount
      self.last_updated_at = Time.current
      save!
    end
  end

  def self.find_or_create_for(group_id, structure_type)
    find_or_create_by!(structure_id: group_id, structure_type: structure_type)
  end
end
