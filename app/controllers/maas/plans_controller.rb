# frozen_string_literal: true

# Gestion des plans tarifaires d'une campagne.
# Imbriqué sous /maas/campagnes/:campagne_id/plans
class Maas::PlansController < ApplicationController
  before_action :authorize_admin
  before_action :set_campaign
  before_action :set_plan, only: [:edit, :update, :destroy]

  def new
    @plan = @campaign.membership_plans.build
  end

  def create
    @plan = @campaign.membership_plans.build(plan_params)

    if @plan.save
      redirect_to maas_campagne_path(@campaign), notice: t("maas.plan.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @plan.update(plan_params)
      redirect_to maas_campagne_path(@campaign), notice: t("maas.plan.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @plan.membership_subscriptions.exists?
      redirect_to maas_campagne_path(@campaign),
                  alert: t("maas.plan.cannot_delete_with_subscriptions")
    else
      @plan.destroy!
      redirect_to maas_campagne_path(@campaign), notice: t("maas.plan.deleted")
    end
  end

  private

  def set_campaign
    @campaign = Maas::MembershipCampaign.find(params[:campagne_id])
  end

  def set_plan
    @plan = @campaign.membership_plans.find(params[:id])
  end

  def plan_params
    params.require(:maas_membership_plan).permit(
      :branche, :montant, :assurance_incluse, :montant_assurance, :minimum_partiel
    )
  end

  def authorize_admin
    authorize!(:manage, Maas::MembershipCampaign)
  end
end
