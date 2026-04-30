# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Tarif national de cotisation pour une branche × une année.
#
# Géré au niveau National par les rôles Trésorier National et Commissaire
# National. Une seule grille par couple (year, branche).
class MembershipFeeRate < ApplicationRecord
  self.table_name = "eeds_membership_fee_rates"

  BRANCHES = MembershipFee::BRANCHES

  validates :year, presence: true,
    numericality: {only_integer: true, greater_than: 1900, less_than: 3000}
  validates :branche, presence: true, inclusion: {in: BRANCHES},
    uniqueness: {scope: :year, case_sensitive: false}
  validates :amount_cents, presence: true,
    numericality: {only_integer: true, greater_than_or_equal_to: 0}

  scope :for_year, ->(year) { where(year: year) }

  def self.lookup(year, branche)
    find_by(year: year, branche: branche.to_s)
  end

  def amount
    amount_cents.to_f / 100
  end
end
