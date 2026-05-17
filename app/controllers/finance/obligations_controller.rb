# frozen_string_literal: true

# Gestion des obligations de paiement (inscriptions des participants).
# Accessible via /groups/:group_id/finance/activity_fees/:activity_fee_id/obligations
class Finance::ObligationsController < ApplicationController
  before_action :set_group
  before_action :set_fee
  before_action :authorize_finance
  before_action :set_obligation, only: [:show, :versement, :create_versement]

  def index
    @obligations = @fee.obligations
                       .includes(:person, :payments)
                       .order(:statut, :created_at)
    @stats = compute_stats(@obligations)
  end

  def show
    @payments = @obligation.payments.order(created_at: :desc)
  end

  def new
    @obligation = @fee.obligations.new(group: @group)
    load_participants
  end

  def create
    person = ::Person.find(params[:person_id])

    @obligation = @fee.obligations.new(
      person: person,
      group: @group,
      montant_total: @fee.montant
    )

    # Si event-based, lier la participation
    if @fee.event? && params[:event_participation_id].present?
      @obligation.event_participation_id = params[:event_participation_id]
    end

    if @obligation.save
      # Paiement initial si montant fourni
      if params[:montant].present? && params[:montant].to_i > 0
        create_initial_payment(@obligation)
      end

      redirect_to group_finance_activity_fee_obligation_path(@group, @fee, @obligation),
                  notice: t("finance.obligation.created")
    else
      load_participants
      render :new, status: :unprocessable_entity
    end
  end

  def versement
    # Formulaire de versement
  end

  def create_versement
    payment = Finance::Payment.new(
      obligation: @obligation,
      enregistre_par: current_user,
      montant: params[:montant].to_i,
      modalite: params[:modalite] || "Cash",
      reference_externe: params[:reference_externe],
      commentaire: params[:commentaire]
    )

    if payment.save
      redirect_to group_finance_activity_fee_obligation_path(@group, @fee, @obligation),
                  notice: t("finance.payment.recorded")
    else
      @errors = payment.errors.full_messages
      render :versement, status: :unprocessable_entity
    end
  end

  private

  def set_group
    @group = ::Group.find(params[:group_id])
  end

  def set_fee
    @fee = Finance::ActivityFee.find(params[:activity_fee_id])
  end

  def set_obligation
    @obligation = @fee.obligations.find(params[:id])
  end

  def load_participants
    if @fee.event?
      # Pour un event : proposer les participants inscrits
      event = @fee.feeable
      already_ids = @fee.obligations.pluck(:person_id)
      @participants = Event::Participation
                        .where(event_id: event.id, active: true)
                        .where.not(participant_id: already_ids)
                        .includes(:participant)
    else
      # Pour une campagne ou standalone : proposer les membres du groupe
      already_ids = @fee.obligations.pluck(:person_id)
      @members = ::Person
                   .joins(:roles)
                   .where(roles: { group_id: @group.self_and_descendants.pluck(:id) })
                   .where.not(id: already_ids)
                   .distinct
                   .order(:last_name, :first_name)
    end
  end

  def create_initial_payment(obligation)
    Finance::Payment.create!(
      obligation: obligation,
      enregistre_par: current_user,
      montant: params[:montant].to_i,
      modalite: params[:modalite] || "Cash",
      reference_externe: params[:reference_externe],
      commentaire: params[:commentaire]
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn("Finance: Paiement initial échoué: #{e.message}")
  end

  def compute_stats(obligations)
    {
      total: obligations.size,
      valide: obligations.count { |o| o.statut == "valide" },
      partiel: obligations.count { |o| o.statut == "partiel" },
      en_attente: obligations.count { |o| o.statut == "en_attente" },
      collected: obligations.sum(&:montant_paye),
      expected: obligations.sum(&:montant_total)
    }
  end

  def authorize_finance
    authorize!(:manage, Finance::Obligation)
  end
end
