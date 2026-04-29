# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Workflow métier d'approbation des candidatures à un camp EEDS.
#
# Inspiré de `Event::Approver` côté PBS, simplifié pour EEDS :
#   - les couches viennent du modèle `Event::Approval::LAYERS`
#   - la chaîne effective est filtrée par les flags `requires_approval_*` du
#     camp et restreinte à l'arbre hiérarchique réel via `Eeds::ApprovalChain`
#   - les rôles approbateurs sont ceux portant la permission
#     `:approve_applications` à la couche concernée
class Eeds::EventApprover
  attr_reader :participation

  def initialize(participation)
    @participation = participation
  end

  def application
    participation.application
  end

  def primary_group
    participation.person&.primary_group
  end

  def open_approval
    @open_approval ||= application&.approvals&.find_by(approved: false, rejected: false)
  end

  # Crée la prochaine Approval requise (si elle n'existe pas déjà). À appeler
  # juste après création de l'Application, et après chaque approve! pour
  # enclencher le niveau suivant.
  def request_approvals
    return unless application && primary_group

    layer = next_required_layer
    request_approval(layer) if layer
  end

  def approve(attrs, user)
    return false unless primary_group && open_approval

    if update_approval(open_approval, true, attrs, user)
      reset_open_approval!
      next_layer = next_required_layer
      if next_layer
        request_approval(next_layer)
      else
        application.update!(approved: true)
      end
      true
    else
      false
    end
  end

  def reject(attrs, user)
    return false unless open_approval

    update_approval(open_approval, false, attrs, user) &&
      application.update!(rejected: true)
  end

  # Personnes habilitées à se prononcer sur l'open_approval courante.
  def current_approvers
    return Person.none unless open_approval && primary_group

    groups = groups_of_layer(open_approval.layer)
    return Person.none if groups.empty?

    approvers_for_groups(groups)
  end

  private

  def reset_open_approval!
    @open_approval = nil
  end

  def update_approval(approval, approved, attrs, user)
    flag = approved ? :approved : :rejected
    approval.update({flag => true,
                     :approver => user,
                     :approved_at => Time.zone.now}.merge(attrs.to_h))
  end

  # Renvoie le nom de la prochaine couche pour laquelle une Approval doit être
  # créée — en respectant 1) la chaîne hiérarchique, 2) les flags du camp,
  # 3) la disponibilité d'au moins un approbateur.
  def next_required_layer
    eligible_layers.find do |layer|
      camp_requires_approval?(layer) && approvers_for_layer(layer).any?
    end
  end

  # Sous-ensemble de `LAYERS` restant à parcourir, après l'éventuelle approval
  # déjà ouverte/approuvée.
  def eligible_layers
    chain = Eeds::ApprovalChain.new(primary_group).layers
    last_approved = application.approvals.where(approved: true).order_by_layer.last
    if last_approved
      idx = Event::Approval::LAYERS.index(last_approved.layer)
      chain.reject { |l| Event::Approval::LAYERS.index(l) <= idx }
    else
      chain
    end
  end

  def camp_requires_approval?(layer)
    participation.event.public_send(:"requires_approval_#{layer}?")
  end

  def request_approval(layer)
    application.approvals.create!(layer: layer) unless application.approvals.exists?(layer: layer)
  end

  def approvers_for_layer(layer)
    groups = groups_of_layer(layer)
    return Person.none if groups.empty?

    approvers_for_groups(groups)
  end

  # Groupes de la hiérarchie correspondant à une couche donnée. On accepte les
  # variantes autonomes (DistrictAutonome compte comme `district`,
  # GroupeLocalAutonome comme `groupe_local`).
  def groups_of_layer(layer)
    primary_group.layer_hierarchy.select do |g|
      Eeds::ApprovalChain::LAYER_FOR_CLASS[g.class.name] == layer
    end
  end

  def approvers_for_groups(groups)
    role_types = approver_role_types_for(groups.first.class)
    Person.joins(:roles)
      .where(roles: {group_id: groups.map(&:id),
                     type: role_types.map(&:sti_name),
                     end_on: [nil, ..Time.zone.today]})
      .distinct
  end

  def approver_role_types_for(group_class)
    group_class.role_types.select do |role|
      role.permissions.include?(:approve_applications)
    end
  end
end
