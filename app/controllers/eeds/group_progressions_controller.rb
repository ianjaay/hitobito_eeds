# frozen_string_literal: true

# Vue Responsable — overview of all members' progressions within a group.
# Accessible at /groups/:group_id/group_progressions
class Eeds::GroupProgressionsController < ApplicationController
  BRANCHE_MAP = { "Group::Woelfe" => "mbootaay", "Group::Pfadi" => "kayon",
                  "Group::Pio" => "dental", "Group::Rover" => "galle" }.freeze

  before_action :set_group
  before_action :authorize_action

  decorates :group

  helper_method :group
  helper Eeds::ProgressionsHelper

  # GET /groups/:group_id/group_progressions
  def index
    @branche = detect_branche(@group)

    # Collect all people in descendant groups that have progressions
    person_ids = Eeds::Progression.where(group_id: @group.self_and_descendants.pluck(:id))
                                   .distinct.pluck(:person_id)
    @members = Person.where(id: person_ids).order(:last_name, :first_name).to_a

    # Build per-member stats — only count progressions matching the group's branch
    all_progs = Eeds::Progression.where(person_id: person_ids, group_id: @group.self_and_descendants.pluck(:id))
                                  .includes(:qualification_kind).to_a
    progs_by_person = all_progs.group_by(&:person_id)

    @member_stats = @members.map do |person|
      progs = progs_by_person[person.id] || []
      # JEEGO are branch-specific, MËN-MËN are branch-agnostic
      jeego = progs.select { |p| p.qualification_kind.category == "jeego" }
      jeego = jeego.select { |p| p.qualification_kind.metadata&.dig("branche") == @branche } if @branche
      menmen = progs.select { |p| p.qualification_kind.category == "menmen" }
      total = jeego.size + menmen.size
      validated = jeego.count(&:validated?) + menmen.count(&:validated?)
      pct = total > 0 ? (validated * 100 / total) : 0

      { person: person, jeego_total: jeego.size, jeego_validated: jeego.count(&:validated?),
        menmen_total: menmen.size, menmen_validated: menmen.count(&:validated?),
        pct: pct, needs_work: progs.count { |p| p.needs_work? },
        status: pct >= 80 ? :excellent : pct >= 50 ? :good : pct >= 30 ? :average : :struggling }
    end

    # Global stats
    total_jeego = all_progs.count { |p| p.qualification_kind.category == "jeego" }
    validated_jeego = all_progs.count { |p| p.qualification_kind.category == "jeego" && p.validated? }
    total_menmen = all_progs.count { |p| p.qualification_kind.category == "menmen" }
    validated_menmen = all_progs.count { |p| p.qualification_kind.category == "menmen" && p.validated? }

    @group_stats = {
      member_count: @members.size,
      avg_pct: @member_stats.any? ? (@member_stats.sum { |s| s[:pct] } / @member_stats.size) : 0,
      alerts: @member_stats.count { |s| s[:status] == :struggling },
      jeego_validated: validated_jeego, jeego_total: total_jeego,
      menmen_validated: validated_menmen, menmen_total: total_menmen
    }
  end

  private

  def group
    @group
  end

  def set_group
    @group = Group.find(params[:group_id])
  end

  def authorize_action
    authorize!(:show, @group)
  end

  def detect_branche(grp)
    current = grp
    while current
      return BRANCHE_MAP[current.type] if BRANCHE_MAP[current.type]
      current = current.parent
    end
    nil
  end
end
