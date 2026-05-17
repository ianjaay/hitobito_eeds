# frozen_string_literal: true

# Tableau de bord financier au niveau d'un groupe.
# Affiche un résumé consolidé de toutes les activités financières (hiérarchique).
# Accessible via /groups/:group_id/finance/dashboard
class Finance::DashboardController < ApplicationController
  before_action :set_group
  before_action :authorize_finance

  def index
    @descendant_group_ids = @group.self_and_descendants.pluck(:id)

    # Toutes les obligations pour ce groupe et ses descendants
    @obligations = Finance::Obligation
                     .where(group_id: @descendant_group_ids)
                     .includes(:activity_fee, :person, :payments)

    # Obligations par catégorie de frais
    @by_categorie = Finance::Obligation
                      .where(group_id: @descendant_group_ids)
                      .joins(:activity_fee)
                      .group("finance_activity_fees.categorie")
                      .select(
                        "finance_activity_fees.categorie",
                        "COUNT(*) as total_count",
                        "SUM(finance_obligations.montant_total) as total_attendu",
                        "SUM(finance_obligations.montant_paye) as total_collecte",
                        "COUNT(CASE WHEN finance_obligations.statut = 'valide' THEN 1 END) as valides",
                        "COUNT(CASE WHEN finance_obligations.statut = 'partiel' THEN 1 END) as partiels"
                      )

    # Stats globales
    @stats = {
      total_obligations: @obligations.count,
      total_attendu: @obligations.sum(:montant_total),
      total_collecte: @obligations.sum(:montant_paye),
      total_valide: @obligations.where(statut: "valide").count,
      total_partiel: @obligations.where(statut: "partiel").count,
      total_en_attente: @obligations.where(statut: "en_attente").count
    }

    # Activités avec des frais dans la hiérarchie
    @activity_fees = Finance::ActivityFee
                       .where(group_id: @descendant_group_ids)
                       .actifs
                       .includes(:feeable)
                       .order(created_at: :desc)

    # Obligations du groupe courant vs sous-groupes
    @own_obligations = @obligations.select { |o| o.group_id == @group.id }
    @sub_group_obligations = @obligations
                               .reject { |o| o.group_id == @group.id }
                               .group_by(&:group)
  end

  private

  def set_group
    @group = ::Group.find(params[:group_id])
  end

  def authorize_finance
    authorize!(:manage, Finance::Obligation)
  end
end
