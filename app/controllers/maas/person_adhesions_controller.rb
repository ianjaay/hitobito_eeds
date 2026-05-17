# frozen_string_literal: true

# Affiche les cotisations d'un membre sur son profil.
# Imbriqué sous /groups/:group_id/people/:person_id/maas_adhesions
class Maas::PersonAdhesionsController < ApplicationController
  before_action :set_group
  before_action :set_person

  helper_method :group, :person

  BRANCHE_COLORS = {
    "Mbootaay" => "#FCD116", "Kayon" => "#2ECC71", "Dental" => "#0054A0",
    "Galle" => "#E74C3C", "National" => "#5D4296", "Gilwell" => "#8B4513"
  }.freeze

  STATUT_CONFIG = {
    "en_attente" => { label: "En attente", color: "#6c757d", icon: "⏳" },
    "partiel"    => { label: "Partiel",    color: "#f0ad4e", icon: "◐" },
    "valide"     => { label: "Validé",     color: "#28a745", icon: "✅" },
    "expire"     => { label: "Expiré",     color: "#dc3545", icon: "⏰" },
    "annule"     => { label: "Annulé",     color: "#6c757d", icon: "✖" }
  }.freeze

  def index
    authorize!(:show, person)

    @subscriptions = Maas::MembershipSubscription
                       .where(member_id: person.id)
                       .includes(:membership_campaign, :membership_plan, :payment_transactions, :receipts)
                       .order(created_at: :desc)

    @active_subscription = @subscriptions.find { |s| Maas::MembershipSubscription::STATUTS_ACTIFS.include?(s.statut) || s.statut == "en_attente" }
    @history = @subscriptions.reject { |s| s == @active_subscription }

    # Tous les reçus du membre pour affichage
    @receipts = Maas::Receipt.for_member(person.id).recent_first
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  def set_person
    @person = Person.find(params[:person_id])
  end

  def group = @group
  def person = @person
end
