# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Liste des personnes à signaler / refuser dans EEDS (mesures de
# protection des jeunes). Géré uniquement au niveau national par les
# administrateurs.
class Blacklist < ActiveRecord::Base
  self.table_name = "eeds_blacklists"

  belongs_to :created_by, class_name: "Person", optional: true

  validates :first_name, :last_name, presence: true
  validates :reference_name, :reference_phone_number, presence: true
  validates :email, format: {with: Devise.email_regexp, allow_blank: true}
  validates :matricule_scout, uniqueness: {allow_blank: true}

  scope :search_by, ->(term) {
    next none if term.blank?

    pattern = "%#{term.to_s.strip}%"
    where("first_name ILIKE :p OR last_name ILIKE :p OR email ILIKE :p OR " \
          "matricule_scout ILIKE :p OR phone_number ILIKE :p", p: pattern)
  }

  def to_s
    [first_name, last_name].compact.join(" ").presence || matricule_scout.to_s
  end
end
