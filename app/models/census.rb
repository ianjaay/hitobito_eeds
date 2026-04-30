# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Recensement annuel EEDS. Une seule entrée par année. La période
# (start_at..finish_at) délimite la fenêtre de saisie pour les groupes
# locaux. La date d'effet (`start_at`) sert également de référence pour
# compter qui est membre actif au moment du recensement.
class Census < ActiveRecord::Base
  self.table_name = "eeds_censuses"

  has_many :member_counts, dependent: :destroy

  after_initialize :set_defaults

  validates :year,     presence: true, uniqueness: true
  validates :start_at, presence: true

  validate :finish_after_start

  class << self
    def last
      order(start_at: :desc).first
    end

    def current
      where("start_at <= ?", Time.zone.today).order(start_at: :desc).first
    end
  end

  def to_s
    year.to_s
  end

  def open?(today = Time.zone.today)
    return false if start_at && start_at > today
    return false if finish_at && finish_at < today

    true
  end

  private

  def set_defaults
    return unless new_record?

    self.start_at ||= Time.zone.today
    self.year ||= start_at.year
  end

  def finish_after_start
    return if finish_at.blank? || start_at.blank?

    errors.add(:finish_at, :greater_than_or_equal_to, count: I18n.l(start_at)) if finish_at < start_at
  end
end
