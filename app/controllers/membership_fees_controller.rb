# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Gestion des cotisations annuelles EEDS d'un Groupe Local.
# Réservé aux porteurs de la permission `:finance` (Trésorier* et au-dessus
# dans la hiérarchie nested-set).
class MembershipFeesController < CrudController
  self.permitted_attrs = [:payment_method, :reference, :paid_at, :comment, :amount_cents]
  self.sort_mappings = {year: :year, status: :status, branche: :branche}

  decorates :group

  skip_authorize_resource
  before_action :authorize_action

  def index
    @year = params[:year].presence&.to_i || default_year
    @branche = params[:branche].presence
    @status = params[:status].presence
    @fees = list_entries.includes(:person, :recorded_by)
  end

  def mark_paid
    if entry.mark_paid!(method: params.require(:membership_fee)[:payment_method],
      recorded_by: current_user,
      reference: params[:membership_fee][:reference],
      paid_at: params[:membership_fee][:paid_at].presence || Time.zone.now,
      comment: params[:membership_fee][:comment])
      redirect_to group_membership_fees_path(@group, year: entry.year),
        notice: I18n.t("membership_fees.flash.paid", default: "Cotisation marquée comme payée.")
    else
      render :show, status: :unprocessable_content
    end
  end

  def mark_exempted
    entry.mark_exempted!(recorded_by: current_user, comment: params.dig(:membership_fee, :comment))
    redirect_to group_membership_fees_path(@group, year: entry.year),
      notice: I18n.t("membership_fees.flash.exempted", default: "Cotisation exemptée.")
  end

  def cancel
    entry.cancel!(recorded_by: current_user, comment: params.dig(:membership_fee, :comment))
    redirect_to group_membership_fees_path(@group, year: entry.year),
      notice: I18n.t("membership_fees.flash.cancelled", default: "Cotisation annulée.")
  end

  def generate
    year = params[:year].to_i
    generator = Eeds::MembershipFeeGenerator.new(group: group, year: year)
    fees = generator.generate!
    redirect_to group_membership_fees_path(@group, year: year),
      notice: I18n.t("membership_fees.flash.generated",
        count: fees.size, missing: generator.missing_rates.join(", "),
        default: "%{count} cotisation(s) générée(s).")
  end

  def remind
    sent = 0
    list_entries.outstanding.includes(:person).find_each do |fee|
      next unless fee.person.email.present?
      MembershipFeeMailer.unpaid_reminder(fee).deliver_later
      sent += 1
    end
    redirect_to group_membership_fees_path(@group, year: @year || default_year),
      notice: I18n.t("membership_fees.flash.reminded", count: sent,
        default: "%{count} rappel(s) envoyé(s).")
  end

  def export
    @year = params[:year].presence&.to_i || default_year
    @branche = params[:branche].presence
    @status  = params[:status].presence
    fees = list_entries.includes(:person, :recorded_by, :group)
    case params[:format]
    when "xlsx"
      send_data Export::Tabular::MembershipFees::List.xlsx(fees),
        type: :xlsx, filename: "cotisations_#{@year}.xlsx"
    else
      send_data Export::Tabular::MembershipFees::List.csv(fees),
        type: :csv, filename: "cotisations_#{@year}.csv"
    end
  end

  private

  def default_year
    Time.zone.today.year
  end

  def list_entries
    scope = MembershipFee.where(group_id: descendant_group_ids)
      .for_year(@year || default_year)
    scope = scope.where(branche: @branche) if @branche.present?
    scope = scope.where(status: @status) if @status.present?
    scope.order(:branche, :status)
  end

  def descendant_group_ids
    g = group
    Group.where("lft >= ? AND rgt <= ?", g.lft, g.rgt).pluck(:id)
  end

  def model_scope
    MembershipFee.where(group_id: group.id)
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def authorize_action
    case action_name
    when "index"
      authorize!(:show, MembershipFee.new(group: group))
    when "export"
      authorize!(:show, MembershipFee.new(group: group))
    when "generate", "remind"
      authorize!(:create, MembershipFee.new(group: group))
    else
      authorize!(:update, entry)
    end
  end

  def return_path
    group_membership_fees_path(@group)
  end
end
