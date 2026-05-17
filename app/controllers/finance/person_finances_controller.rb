# frozen_string_literal: true

# Finances d'un membre : onglet profil.
# Accessible via /groups/:group_id/people/:person_id/finances
class Finance::PersonFinancesController < ApplicationController
  before_action :set_group_and_person
  before_action :authorize_finance

  def index
    @obligations = Finance::Obligation
                     .for_person(@person.id)
                     .includes(:activity_fee, :payments, :group)
                     .order(created_at: :desc)

    @active_obligations = @obligations.select { |o| %w[en_attente partiel].include?(o.statut) }
    @completed_obligations = @obligations.select { |o| o.statut == "valide" }
    @history = @obligations.select { |o| %w[expire annule].include?(o.statut) }

    @receipts = Finance::Receipt
                  .for_person(@person.id)
                  .recent_first
                  .limit(20)

    @stats = {
      total_obligations: @obligations.size,
      total_paye: @obligations.sum(&:montant_paye),
      total_du: @obligations.sum(&:solde_restant),
      total_valide: @completed_obligations.size
    }
  end

  private

  def set_group_and_person
    @group = ::Group.find(params[:group_id])
    @person = ::Person.find(params[:person_id])
  end

  def authorize_finance
    authorize!(:show, @person)
  end
end
