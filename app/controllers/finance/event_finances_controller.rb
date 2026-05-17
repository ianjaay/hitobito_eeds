# frozen_string_literal: true

# Vue financière d'un event (camp, cours, formation).
# Accessible via /groups/:group_id/events/:event_id/finances
class Finance::EventFinancesController < ApplicationController
  before_action :set_group
  before_action :set_event
  before_action :authorize_finance

  def index
    @fees = Finance::ActivityFee.for_event(@event).actifs.order(:categorie)
    @all_obligations = Finance::Obligation
                         .where(activity_fee_id: @fees.pluck(:id))
                         .includes(:person, :payments, :activity_fee)

    @stats = {
      total_frais: @fees.count,
      total_participants: @all_obligations.select(:person_id).distinct.count,
      total_attendu: @all_obligations.sum(:montant_total),
      total_collecte: @all_obligations.sum(:montant_paye),
      total_valide: @all_obligations.where(statut: "valide").count,
      total_partiel: @all_obligations.where(statut: "partiel").count
    }
  end

  private

  def set_group
    @group = ::Group.find(params[:group_id])
  end

  def set_event
    @event = Event.find(params[:event_id])
  end

  def authorize_finance
    authorize!(:manage, Finance::ActivityFee)
  end
end
