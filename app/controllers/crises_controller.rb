# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

class CrisesController < CrudController
  self.permitted_attrs = [:kind, :severity, :description]

  decorates :group

  skip_authorize_resource
  before_action :authorize_action

  def index
    @entries = Crisis.for_group(group).order(created_at: :desc).includes(:creator)
  end

  def create
    assign_attributes
    entry.creator = current_user
    entry.group   = group
    if entry.save
      CrisisMailer.triggered(entry).deliver_later
      redirect_to group_crises_path(group),
        notice: I18n.t("crises.flash.created", default: "Crise déclenchée.")
    else
      render :new, status: :unprocessable_content
    end
  end

  def acknowledge
    if entry.acknowledge!(current_user)
      CrisisMailer.acknowledged(entry).deliver_later
      redirect_to group_crises_path(group),
        notice: I18n.t("crises.flash.acknowledged", default: "Crise acquittée.")
    else
      redirect_to group_crises_path(group),
        alert: I18n.t("crises.flash.cannot_acknowledge", default: "Impossible d'acquitter.")
    end
  end

  def complete
    entry.complete!(current_user)
    CrisisMailer.completed(entry).deliver_later
    redirect_to group_crises_path(group),
      notice: I18n.t("crises.flash.completed", default: "Crise clôturée.")
  end

  private

  def model_scope
    Crisis.where(group_id: group.id)
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def authorize_action
    case action_name
    when "index", "show"
      authorize!(:show, Crisis.new(group: group))
    when "new", "create"
      authorize!(:create, Crisis.new(group: group, creator: current_user))
    when "acknowledge"
      authorize!(:acknowledge, entry)
    when "complete"
      authorize!(:complete, entry)
    else
      authorize!(:update, entry)
    end
  end

  def return_path
    group_crises_path(@group)
  end
end
