# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Notifie les approbateurs courants qu'une candidature attend leur décision.
class Event::ApprovalMailer < ApplicationMailer
  CONTENT_NEXT_APPROVERS = "event_approval_next_approvers"

  def notify_next_approvers(application)
    @application = application
    @participation = application.participation
    @approvee = @participation.person
    @event = @participation.event
    @approver_service = Eeds::EventApprover.new(@participation)
    @open_approval = @approver_service.open_approval

    return if @open_approval.nil?

    recipients = @approver_service.current_approvers.where.not(email: [nil, ""])
    return if recipients.empty?

    custom_content_mail(
      recipients.pluck(:email),
      CONTENT_NEXT_APPROVERS,
      values_for_placeholders(CONTENT_NEXT_APPROVERS)
    )
  end

  private

  def placeholder_camp_name
    @event.name
  end

  def placeholder_applicant_name
    @approvee.to_s
  end

  def placeholder_layer
    Event::Approval.human_attribute_name("layers.#{@open_approval.layer}",
      default: @open_approval.layer.to_s)
  end

  def placeholder_application_url
    link_to(group_event_participation_url(@event.groups.first, @event, @participation))
  end
end
