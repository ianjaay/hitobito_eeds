# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Controller pour le workflow d'approbation des candidatures aux camps EEDS.
class Event::ApprovalsController < CrudController
  self.permitted_attrs = [:comment]

  decorates :group, :event, :participation

  def index
    @approvals = entries.includes(:approver).group_by(&:participation)
  end

  def new
    redirect_to participation_path unless entry && safe_decision
  end

  def create
    if approver.send(decision, permitted_params, current_user)
      Event::ApprovalMailer.notify_next_approvers(participation.application).deliver_later if decision == "approve"
      flash[:notice] = notice_for(decision)
      redirect_to participation_path
    else
      @approval = approver.open_approval
      render "new", status: :unprocessable_content
    end
  end

  def self.model_class
    Event::Approval
  end

  private

  def participation_path
    group_event_participation_path(@group, participation.event_id, participation)
  end

  def model_ivar_set(entry)
    @approval = entry
  end

  def decision
    @decision ||= params[:decision].to_s.tap do |d|
      raise ArgumentError, "Invalid decision #{d}" unless %w[approve reject].include?(d)
    end
  end

  def safe_decision
    decision
  rescue ArgumentError
    nil
  end

  def approver
    @approver ||= Eeds::EventApprover.new(participation.reload)
  end

  def notice_for(decision)
    I18n.t("event/approvals.flash.#{decision}d", default: decision.to_s.capitalize)
  end

  def build_entry
    participation.application&.approvals&.find_by(approved: false, rejected: false)
  end

  def list_entries
    Event::Approval
      .joins(application: :participation)
      .where(event_participations: {event_id: event.id, active: true})
      .includes(approver: [:phone_numbers, :roles, :groups],
        participation: [:event, :application])
      .order_by_layer
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def event
    @event ||= group.events.find(params[:event_id])
  end

  def model_scope
    participation.application.approvals
  end

  def participation
    @participation ||= event.participations.find(params[:participation_id])
  end

  def authorize_class
    authorize!(:index_participations, event)
  end

  def return_path
    group_event_participation_path(@group, @event, @participation)
  end
end
