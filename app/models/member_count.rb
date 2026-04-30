# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Effectifs d'un groupe local pour une année (recensement). Pour chaque
# branche EEDS et la catégorie « encadrement », on stocke le décompte
# par sexe (f / m / u où u = inconnu / non renseigné).
class MemberCount < ActiveRecord::Base
  self.table_name = "eeds_member_counts"

  CATEGORIES = %i[jiwu lawtan toor_toor menneef encadrement].freeze
  GENDERS    = %i[f m u].freeze
  COUNT_COLUMNS = CATEGORIES.flat_map { |c| GENDERS.map { |g| :"#{c}_#{g}" } }.freeze

  belongs_to :group
  belongs_to :census, optional: true

  validates :year,     presence: true
  validates :group_id, presence: true, uniqueness: {scope: :year}
  validates(*COUNT_COLUMNS, numericality: {greater_than_or_equal_to: 0, allow_nil: true})

  scope :for_year, ->(year) { where(year: year.to_i) }

  CATEGORIES.each do |c|
    define_method(c) do
      send(:"#{c}_f").to_i + send(:"#{c}_m").to_i + send(:"#{c}_u").to_i
    end
  end

  def total
    CATEGORIES.sum { |c| send(c) }
  end

  def total_f = sum_gender(:f)
  def total_m = sum_gender(:m)
  def total_u = sum_gender(:u)

  private

  def sum_gender(g)
    CATEGORIES.sum { |c| send(:"#{c}_#{g}").to_i }
  end
end
