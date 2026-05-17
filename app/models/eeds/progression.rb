# frozen_string_literal: true

# Modèle central de suivi pédagogique EEDS.
# Chaque enregistrement représente la progression d'un jeune (Person)
# sur un JEEGO (épreuve collective) ou un MËN-MËN (brevet individuel).
#
# Statuts : not_started → in_progress → validated
#                           ↘ needs_work → in_progress (après délai)
class Eeds::Progression < ApplicationRecord
  self.table_name = "eeds_progressions"

  belongs_to :person, class_name: "::Person"
  belongs_to :qualification_kind, class_name: "::QualificationKind"
  belongs_to :group, class_name: "::Group"
  belongs_to :validated_by, class_name: "::Person", optional: true
  belongs_to :event, class_name: "::Event", optional: true

  has_many :logs, class_name: "Eeds::ProgressionLog",
                  foreign_key: :eeds_progression_id,
                  dependent: :destroy

  enum :status, {
    not_started: 0,
    in_progress: 1,
    needs_work: 2,
    validated: 3
  }

  validates :notes, presence: true, if: :needs_work?
  validate :prerequisite_satisfied, on: :update, if: :validated?
  validate :validator_is_not_self, if: :validated_by_id
  validate :resubmission_delay, if: :transitioning_from_needs_work?

  before_save :set_validated_at, if: -> { validated? && validated_at.blank? }
  after_save :create_qualification_record, if: -> { saved_change_to_status? && validated? }
  after_save :write_audit_log, if: :saved_change_to_status?

  scope :for_person, ->(person_id) { where(person_id: person_id) }
  scope :for_group, ->(group_id) { where(group_id: group_id) }
  scope :jeego, -> { joins(:qualification_kind).where(qualification_kinds: { category: "jeego" }) }
  scope :menmen, -> { joins(:qualification_kind).where(qualification_kinds: { category: "menmen" }) }
  scope :active, -> { where.not(status: :not_started) }
  scope :stalled, -> { where(status: :needs_work).where("eeds_progressions.updated_at < ?", 3.months.ago) }

  def criteria_validated_count
    Array(criteria_met).size
  end

  def criteria_total
    qualification_kind.respond_to?(:criteria) ? qualification_kind.criteria.count : 0
  end

  def criteria_complete?
    min = qualification_kind.metadata&.dig("minimum_criteria") || criteria_total
    criteria_validated_count >= min
  end

  private

  def prerequisite_satisfied
    prereq_key = qualification_kind.metadata&.dig("prerequisite")
    return if prereq_key.blank?

    prereq = ::QualificationKind.find_by(key: prereq_key)
    return unless prereq

    unless Eeds::Progression.exists?(
      person_id: person_id,
      qualification_kind_id: prereq.id,
      status: :validated
    )
      errors.add(:base, "Le prérequis « #{prereq.label} » n'est pas encore validé")
    end
  end

  def validator_is_not_self
    if validated_by_id == person_id
      errors.add(:validated_by, "Un responsable ne peut pas valider sa propre progression")
    end
  end

  def resubmission_delay
    min_delay = 14 # jours
    if updated_at.present? && updated_at > min_delay.days.ago
      errors.add(:base, "Délai minimum de #{min_delay} jours avant re-soumission")
    end
  end

  def transitioning_from_needs_work?
    status_changed? && status_was == "needs_work" && in_progress?
  end

  def set_validated_at
    self.validated_at = Time.current
  end

  def create_qualification_record
    ::Qualification.find_or_create_by!(
      person_id: person_id,
      qualification_kind_id: qualification_kind_id
    ) do |q|
      q.start_at = validated_at
      q.origin = event&.name || "Validation directe"
    end
  end

  def write_audit_log
    old_status, new_status = saved_change_to_status
    logs.create!(
      actor: validated_by || person,
      action: "status_change",
      old_value: old_status,
      new_value: new_status,
      notes: notes
    )
  end
end
