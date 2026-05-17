# frozen_string_literal: true

# Gestion des frais associés aux activités (events ou campagnes).
# Accessible via /groups/:group_id/finance/activity_fees
class Finance::ActivityFeesController < ApplicationController
  include Admin::FeatureAccessConcern

  before_action :set_group
  before_action :authorize_finance
  before_action -> { check_feature_access!("finance") }
  before_action :set_fee, only: [:show, :edit, :update, :destroy]

  def index
    @fees = Finance::ActivityFee
              .where(group_id: @group.id)
              .actifs
              .includes(:feeable)
              .order(created_at: :desc)
  end

  def show
    @obligations = @fee.obligations.includes(:person, :payments).order(:statut, :created_at)
    @stats = {
      total: @obligations.count,
      valide: @obligations.where(statut: "valide").count,
      partiel: @obligations.where(statut: "partiel").count,
      en_attente: @obligations.where(statut: "en_attente").count,
      collected: @obligations.sum(:montant_paye),
      expected: @obligations.sum(:montant_total)
    }
  end

  def new
    @fee = Finance::ActivityFee.new(group: @group)
    load_feeables
  end

  def create
    @fee = Finance::ActivityFee.new(fee_params)
    @fee.group = @group

    # Seul le niveau national peut créer des frais de type cotisation
    if @fee.feeable_type == "Maas::MembershipCampaign" && !(@group.is_a?(Group::Root) || @group.is_a?(Group::Bund))
      @fee.errors.add(:base, "Seul le niveau national peut creer des frais de type cotisation")
      load_feeables
      return render :new, status: :unprocessable_entity
    end

    if @fee.save
      redirect_to group_finance_activity_fee_path(@group, @fee),
                  notice: t("finance.activity_fee.created")
    else
      load_feeables
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_feeables
  end

  def update
    if @fee.update(fee_params)
      redirect_to group_finance_activity_fee_path(@group, @fee),
                  notice: t("finance.activity_fee.updated")
    else
      load_feeables
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @fee.obligations.exists?
      redirect_to group_finance_activity_fee_path(@group, @fee),
                  alert: t("finance.activity_fee.cannot_delete_with_obligations")
    else
      @fee.destroy!
      redirect_to group_finance_activity_fees_path(@group),
                  notice: t("finance.activity_fee.deleted")
    end
  end

  private

  def set_group
    @group = ::Group.find(params[:group_id])
  end

  def set_fee
    @fee = Finance::ActivityFee.find(params[:id])
  end

  def fee_params
    params.require(:finance_activity_fee).permit(
      :libelle, :categorie, :montant, :montant_assurance, :minimum_partiel,
      :branche, :obligatoire, :actif, :description, :feeable_type, :feeable_id
    )
  end

  def load_feeables
    # Événements du groupe (camps, cours, activités)
    @events = Event.joins("INNER JOIN events_groups ON events.id = events_groups.event_id")
                   .where("events_groups.group_id = ?", @group.id)
                   .where("events.state IS NULL OR events.state != 'closed'")
                   .order(created_at: :desc)
                   .limit(50)

    # Seul le niveau national (Group::Root / Group::Bund) peut créer des frais de type cotisation
    @can_create_cotisation = @group.is_a?(Group::Root) || @group.is_a?(Group::Bund)
    @campaigns = @can_create_cotisation ? Maas::MembershipCampaign.where(statut: %w[brouillon active]).order(annee: :desc) : []
  end

  def authorize_finance
    authorize!(:manage, Finance::ActivityFee)
  end
end
