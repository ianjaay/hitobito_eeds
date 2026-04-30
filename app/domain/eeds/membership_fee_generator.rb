# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Génère les cotisations annuelles pour les membres actifs d'un Groupe
# Local pour une année donnée. Utilise les tarifs `MembershipFeeRate` en
# vigueur. Les membres sans branche identifiable (chef de groupe seul,
# trésorier...) sont rattachés à la branche `encadrement`.
#
# Usage :
#   Eeds::MembershipFeeGenerator.new(group: gl, year: 2026).generate!
#   # => [#<MembershipFee>, ...]
class Eeds::MembershipFeeGenerator
  GROUP_TO_BRANCHE = {
    "Group::Mbootaay" => "jiwu",
    "Group::Kayon"    => "lawtan",
    "Group::Nawka"    => "toor_toor",
    "Group::Galle"    => "menneef"
  }.freeze

  attr_reader :group, :year, :missing_rates

  def initialize(group:, year:)
    @group = group
    @year = year.to_i
    @missing_rates = []
  end

  # Crée les cotisations manquantes ; renvoie le tableau de toutes les
  # cotisations (existantes + nouvellement créées) pour l'année et le groupe.
  def generate!
    fees = []
    eligible_people.find_each do |person|
      branche = branche_for(person)
      rate = MembershipFeeRate.lookup(year, branche)
      unless rate
        @missing_rates << branche unless @missing_rates.include?(branche)
        next
      end

      fee = MembershipFee.find_or_initialize_by(person_id: person.id, year: year)
      next if fee.persisted? # déjà générée, on ne la remplace pas

      fee.assign_attributes(
        group: group,
        branche: branche,
        amount_cents: rate.amount_cents,
        currency: rate.currency,
        status: "pending"
      )
      fee.save!
      fees << fee
    end
    fees
  end

  private

  # Personnes ayant un rôle actif dans la sous-arborescence du groupe local.
  def eligible_people
    person_ids = Role.where(group_id: descendant_group_ids).pluck(:person_id).uniq
    Person.where(id: person_ids)
  end

  def descendant_group_ids
    g = group.reload
    Group.where("lft >= ? AND rgt <= ?", g.lft, g.rgt).pluck(:id)
  end

  # Détermine la branche d'un membre via son rôle dans une unité (Mbootaay,
  # Kayon, Nawka, Galle). Sinon « encadrement ».
  def branche_for(person)
    role = person.roles.includes(:group)
      .find { |r| GROUP_TO_BRANCHE.key?(r.group.class.name) && active?(r) }
    role ? GROUP_TO_BRANCHE[role.group.class.name] : "encadrement"
  end

  def active?(role)
    role.end_on.nil? || role.end_on >= Time.zone.today
  end
end
