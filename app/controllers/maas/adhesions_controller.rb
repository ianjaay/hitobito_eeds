# frozen_string_literal: true

# Interface responsable local : gestion des adhésions de son groupe.
# Accessible via /groups/:group_id/maas/adhesions
class Maas::AdhesionsController < ApplicationController
  include Admin::FeatureAccessConcern

  before_action :set_group
  before_action :authorize_local
  before_action -> { check_feature_access!("maas") }
  before_action :set_subscription, only: [:show, :versement, :create_versement]

  helper_method :branche_colors, :statut_config

  def index
    @campaign = Maas::MembershipCampaign.active.first
    return redirect_to group_path(@group), alert: t("maas.adhesion.no_active_campaign") unless @campaign

    # Récupérer les IDs de tous les sous-groupes dans la hiérarchie
    @descendant_group_ids = @group.self_and_descendants.pluck(:id)

    @subscriptions = Maas::MembershipSubscription
                       .where(group_id: @descendant_group_ids)
                       .for_campaign(@campaign.id)
                       .includes(:member, :membership_plan, :payment_transactions, :group)
                       .order(:statut, :created_at)

    # Adhésions du groupe courant seulement
    @own_subscriptions = @subscriptions.select { |s| s.group_id == @group.id }
    # Adhésions des sous-groupes, groupées par groupe
    @sub_group_subscriptions = @subscriptions
                                 .reject { |s| s.group_id == @group.id }
                                 .group_by(&:group)

    @stats = {
      total: @subscriptions.size,
      valide: @subscriptions.count { |s| s.statut == "valide" },
      partiel: @subscriptions.count { |s| s.statut == "partiel" },
      en_attente: @subscriptions.count { |s| s.statut == "en_attente" },
      collected: @subscriptions.sum(&:montant_paye),
      expected: @subscriptions.sum(&:montant_total)
    }
  end

  def show
    @transactions = @subscription.payment_transactions.order(created_at: :desc)
  end

  def new
    @campaign = Maas::MembershipCampaign.active.first
    return redirect_to group_path(@group), alert: t("maas.adhesion.no_active_campaign") unless @campaign

    @plans = @campaign.membership_plans.order(:branche)
    @members = available_members
  end

  def create
    @campaign = Maas::MembershipCampaign.active.first
    plan = @campaign.membership_plans.find(params[:plan_id])
    member = ::Person.find(params[:member_id])

    service = Maas::AdhesionService.new(
      campaign: @campaign,
      plan: plan,
      member: member,
      group: @group,
      enregistre_par: current_user
    )

    if service.create_subscription!(
      montant: params[:montant],
      modalite: params[:modalite] || "Cash",
      reference: params[:reference_manuelle],
      notes: params[:notes]
    )
      redirect_to group_maas_adhesion_path(@group, service.subscription),
                  notice: t("maas.adhesion.created")
    else
      @plans = @campaign.membership_plans.order(:branche)
      @members = available_members
      @errors = service.errors
      render :new, status: :unprocessable_entity
    end
  end

  def versement
    @plan = @subscription.membership_plan
  end

  def create_versement
    service = Maas::AdhesionService.new(
      campaign: @subscription.membership_campaign,
      plan: @subscription.membership_plan,
      member: @subscription.member,
      group: @group,
      enregistre_par: current_user
    )
    service.instance_variable_set(:@subscription, @subscription)

    begin
      service.record_payment!(
        montant: params[:montant],
        modalite: params[:modalite] || "Cash",
        reference: params[:reference_manuelle],
        notes: params[:notes]
      )
      redirect_to group_maas_adhesion_path(@group, @subscription),
                  notice: t("maas.adhesion.payment_recorded")
    rescue ActiveRecord::RecordInvalid => e
      @plan = @subscription.membership_plan
      @errors = [e.message]
      render :versement, status: :unprocessable_entity
    end
  end

  private

  def set_group
    @group = ::Group.find(params[:group_id])
  end

  def set_subscription
    descendant_ids = @group.self_and_descendants.pluck(:id)
    @subscription = Maas::MembershipSubscription
                      .where(group_id: descendant_ids)
                      .find(params[:id])
  end

  def authorize_local
    authorize!(:update, @group)
  end

  def available_members
    # Membres du groupe qui n'ont pas encore d'adhésion pour la campagne active
    campaign = Maas::MembershipCampaign.active.first
    return [] unless campaign

    existing_member_ids = Maas::MembershipSubscription
                            .for_campaign(campaign.id)
                            .pluck(:member_id)

    ::Person.joins(:roles)
            .where(roles: { group_id: @group.id })
            .where.not(id: existing_member_ids)
            .distinct
            .order(:last_name, :first_name)
  end

  def branche_colors
    { "Mbootaay" => "#FCD116", "Kayon" => "#2ECC71", "Dental" => "#0054A0",
      "Galle" => "#E74C3C", "National" => "#5D4296", "Gilwell" => "#1e293b" }
  end

  def statut_config
    { "en_attente" => { bg: "#f1f5f9", fg: "#94a3b8", label: "En attente" },
      "partiel"    => { bg: "#fef3c7", fg: "#f59e0b", label: "Partiel" },
      "valide"     => { bg: "#d1fae5", fg: "#10b981", label: "Validé" },
      "expire"     => { bg: "#fee2e2", fg: "#ef4444", label: "Expiré" },
      "annule"     => { bg: "#fecaca", fg: "#dc2626", label: "Annulé" } }
  end
end
