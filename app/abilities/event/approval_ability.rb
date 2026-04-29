# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Habilitation CanCan pour la prise de décision sur une `Event::Approval`.
#
# Règles :
#   - L'utilisateur doit posséder un rôle portant `:approve_applications`
#   - dans un groupe situé dans la chaîne hiérarchique du candidat (approvee)
#   - et dont la couche correspond à celle de l'approval (groupe_local /
#     district / region / national, autonomes inclus).
#   - Pas d'action possible une fois le camp commencé.
class Event::ApprovalAbility < AbilityDsl::Base
  on(Event::Approval) do
    permission(:approve_applications).may(:create).for_open_approval_in_same_layer
    permission(:approve_applications).may(:update).for_open_approval_in_same_layer
    general(:create).only_before_camp_started
    general(:update).only_before_camp_started
  end

  def for_open_approval_in_same_layer
    return false if subject.approved? || subject.rejected?
    return false unless approvee_primary_group

    approver_role_types = approver_role_types_for(layer_group_class)
    user.roles.any? do |role|
      approver_role_types.include?(role.class) &&
        approval_layer_group_ids.include?(role.group_id) &&
        role.active?
    end
  end

  def only_before_camp_started
    return true unless subject.event && subject.event.dates.any?

    Time.zone.today < subject.event.dates.minimum(:start_at).to_date
  end

  private

  def approvee_primary_group
    @approvee_primary_group ||= subject.approvee&.primary_group
  end

  def layer_group_class
    case subject.layer
    when "groupe_local" then Group::GroupeLocal
    when "district"     then Group::District
    when "region"       then Group::RegionEeds
    when "national"     then Group::National
    end
  end

  def approval_layer_group_ids
    approvee_primary_group.layer_hierarchy.select do |g|
      Eeds::ApprovalChain::LAYER_FOR_CLASS[g.class.name] == subject.layer
    end.map(&:id)
  end

  def approver_role_types_for(group_class)
    return [] unless group_class

    # Inclut variantes autonomes (DistrictAutonome partage les mêmes types de
    # rôles que District au sens fonctionnel).
    related_classes = Group.descendants.select do |g|
      Eeds::ApprovalChain::LAYER_FOR_CLASS[g.name] == subject.layer
    end
    related_classes.flat_map(&:role_types).select do |role|
      role.permissions.include?(:approve_applications)
    end.uniq
  end
end
