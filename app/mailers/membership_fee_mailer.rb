# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Notification adressée à un membre EEDS pour rappeler une cotisation impayée.
class MembershipFeeMailer < ApplicationMailer
  CONTENT_UNPAID_REMINDER = "membership_fee_unpaid_reminder"

  def unpaid_reminder(fee)
    @fee = fee
    @person = fee.person
    @group = fee.group

    return if @person.email.blank?

    custom_content_mail(
      [@person.email],
      CONTENT_UNPAID_REMINDER,
      values_for_placeholders(CONTENT_UNPAID_REMINDER)
    )
  end

  private

  def placeholder_recipient_name
    @person.to_s
  end

  def placeholder_year
    @fee.year.to_s
  end

  def placeholder_branche
    MembershipFee.human_attribute_name("branches.#{@fee.branche}", default: @fee.branche.to_s)
  end

  def placeholder_amount
    format("%d %s", @fee.amount.to_i, @fee.currency)
  end

  def placeholder_group_name
    @group.to_s
  end
end
