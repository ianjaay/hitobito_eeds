# frozen_string_literal: true

# Administration nationale des campagnes d'adhésion.
# Accessible uniquement aux administrateurs nationaux (layer_full sur Root).
class Maas::CampagnesController < ApplicationController
  before_action :authorize_admin
  before_action :set_campaign, only: [:show, :edit, :update, :destroy, :activate, :fermer, :archiver]

  helper_method :branche_colors

  def index
    @campaigns = Maas::MembershipCampaign.order(annee: :desc)
    @active_campaign = Maas::MembershipCampaign.active.first
    @stats = compute_global_stats
  end

  def show
    @plans = @campaign.membership_plans.order(:branche)
    @subscriptions = @campaign.membership_subscriptions.includes(:member, :membership_plan)
    @stats = compute_campaign_stats(@campaign)
  end

  def new
    @campaign = Maas::MembershipCampaign.new(
      annee: Date.current.year.to_s,
      date_ouverture: Date.current,
      date_fermeture: Date.new(Date.current.year, 12, 31)
    )
  end

  def create
    @campaign = Maas::MembershipCampaign.new(campaign_params)
    @campaign.created_by = current_user

    if @campaign.save
      redirect_to maas_campagne_path(@campaign), notice: t("maas.campagne.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @campaign.update(campaign_params)
      redirect_to maas_campagne_path(@campaign), notice: t("maas.campagne.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def activate
    @campaign.update!(statut: "active")
    redirect_to maas_campagne_path(@campaign), notice: t("maas.campagne.activated")
  end

  def fermer
    @campaign.update!(statut: "fermee")
    redirect_to maas_campagne_path(@campaign), notice: t("maas.campagne.closed")
  end

  def archiver
    @campaign.update!(statut: "archivee")
    redirect_to maas_campagnes_path, notice: t("maas.campagne.archived")
  end

  def destroy
    if @campaign.membership_subscriptions.exists?
      redirect_to maas_campagne_path(@campaign),
                  alert: t("maas.campagne.cannot_delete_with_subscriptions")
    else
      @campaign.destroy!
      redirect_to maas_campagnes_path, notice: t("maas.campagne.deleted")
    end
  end

  private

  def set_campaign
    @campaign = Maas::MembershipCampaign.find(params[:id])
  end

  def campaign_params
    params.require(:maas_membership_campaign).permit(
      :annee, :date_ouverture, :date_fermeture, :description
    )
  end

  def authorize_admin
    authorize!(:manage, Maas::MembershipCampaign)
  end

  def compute_global_stats
    active = Maas::MembershipCampaign.active.first
    return {} unless active

    subs = active.membership_subscriptions
    {
      total_members: subs.where(statut: %w[partiel valide]).count,
      total_valide: subs.where(statut: "valide").count,
      total_collected: subs.sum(:montant_paye),
      total_expected: subs.sum(:montant_total)
    }
  end

  def compute_campaign_stats(campaign)
    subs = campaign.membership_subscriptions
    {
      total: subs.count,
      en_attente: subs.where(statut: "en_attente").count,
      partiel: subs.where(statut: "partiel").count,
      valide: subs.where(statut: "valide").count,
      expire: subs.where(statut: "expire").count,
      collected: subs.sum(:montant_paye),
      expected: subs.sum(:montant_total),
      by_branche: subs.joins(:membership_plan)
                       .group("maas_membership_plans.branche")
                       .count
    }
  end

  def branche_colors
    {
      "Mbootaay" => "#FCD116",
      "Kayon"    => "#2ECC71",
      "Dental"   => "#0054A0",
      "Galle"    => "#E74C3C",
      "National" => "#5D4296",
      "Gilwell"  => "#1e293b"
    }
  end
end
