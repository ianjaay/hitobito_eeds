# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Calcule (et persiste) les effectifs d'un Groupe Local pour une année
# donnée à partir des rôles actifs présents dans la sous-arborescence du
# groupe. Les chefs et adultes responsables sont placés sous la catégorie
# `encadrement`; les autres membres sont classés selon la branche de
# l'unité où se trouve leur rôle.
class Eeds::MemberCountGenerator
  GROUP_TO_BRANCHE = Eeds::MembershipFeeGenerator::GROUP_TO_BRANCHE
  CATEGORIES = MemberCount::CATEGORIES

  attr_reader :group, :year, :census

  def initialize(group:, year:, census: nil)
    @group  = group
    @year   = year.to_i
    @census = census
  end

  # Calcule et upsert un MemberCount pour `group`/`year`.
  def run!
    counts = blank_counts
    active_roles_by_person.each do |_pid, roles|
      branche = pick_branche(roles)
      gender  = roles.first.person.gender
      bucket  = gender_bucket(gender)
      counts[branche][bucket] += 1
    end

    record = MemberCount.find_or_initialize_by(group_id: group.id, year: year)
    record.assign_attributes(census: census || record.census)
    flatten_counts_into(record, counts)
    record.save!
    record
  end

  private

  def blank_counts
    CATEGORIES.index_with { {f: 0, m: 0, u: 0} }
  end

  def flatten_counts_into(record, counts)
    counts.each do |cat, by_gender|
      by_gender.each do |gender, n|
        record.send(:"#{cat}_#{gender}=", n)
      end
    end
  end

  # Regroupe les rôles actifs par personne dans la sous-arborescence.
  def active_roles_by_person
    g = group.reload
    descendants = Group.where("lft >= ? AND rgt <= ?", g.lft, g.rgt).pluck(:id)
    Role.includes(:person, :group)
      .where(group_id: descendants)
      .select { |r| active?(r) }
      .group_by(&:person_id)
  end

  def active?(role)
    role.end_on.nil? || role.end_on >= reference_date
  end

  def reference_date
    census&.start_at || Date.new(year, 12, 31)
  end

  # Une personne peut avoir plusieurs rôles : on privilégie un rôle
  # « membre encadré » (standard_role d'une unité) pour la classer dans
  # la branche correspondante; sinon elle est rangée dans `encadrement`.
  def pick_branche(roles)
    member_role = roles.find { |r| member_role?(r) }
    return GROUP_TO_BRANCHE[member_role.group.class.name].to_sym if member_role

    :encadrement
  end

  def member_role?(role)
    branche_class = GROUP_TO_BRANCHE.key?(role.group.class.name)
    return false unless branche_class

    standard = role.group.class.respond_to?(:standard_role) && role.group.class.standard_role
    standard && role.is_a?(standard)
  end

  def gender_bucket(gender)
    case gender
    when "w", "f" then :f
    when "m"      then :m
    else               :u
    end
  end
end
