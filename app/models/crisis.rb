# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Crise / incident grave EEDS. Déclenché par un chef de groupe ou un
# commissaire pour signaler accident, abus, conflit, problème de santé ou
# autre, sur un Groupe Local. Tant qu'elle n'est pas complétée, une seule
# crise active par groupe est autorisée.
class Crisis < ActiveRecord::Base
  self.table_name = "eeds_crises"

  KINDS      = %w[accident abus conflit sante autre].freeze
  SEVERITIES = %w[low medium high critical].freeze

  belongs_to :group
  belongs_to :creator,         class_name: "Person"
  belongs_to :acknowledged_by, class_name: "Person", optional: true
  belongs_to :completed_by,    class_name: "Person", optional: true

  validates :kind,     presence: true, inclusion: {in: KINDS}
  validates :severity, presence: true, inclusion: {in: SEVERITIES}
  validates :group_id, presence: true
  validates :creator_id, presence: true

  validate :no_other_active_crisis_on_group, on: :create

  scope :active,    -> { where(completed: false) }
  scope :pending,   -> { active.where(acknowledged: false) }
  scope :for_group, ->(g) { where(group_id: g.id) }

  def acknowledge!(person)
    return false if completed?

    update!(acknowledged: true, acknowledged_by: person, acknowledged_at: Time.zone.now)
  end

  def complete!(person)
    update!(completed: true, completed_by: person, completed_at: Time.zone.now)
  end

  def status
    return :completed if completed?
    return :acknowledged if acknowledged?

    :pending
  end

  private

  def no_other_active_crisis_on_group
    return unless group_id

    if Crisis.active.where(group_id: group_id).where.not(id: id).exists?
      errors.add(:base, I18n.t("crises.errors.another_active",
        default: "Une crise active existe déjà sur ce groupe."))
    end
  end
end
