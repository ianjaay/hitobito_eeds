# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Workflow d'approbation EEDS.
#
# Une `Event::Approval` représente la décision d'un niveau hiérarchique
# (Groupe Local → District → Région → National) sur une `Event::Application`
# (candidature à un camp). L'ordre des niveaux dans `LAYERS` est significatif :
# la remontée se fait dans cet ordre.
#
# Les Districts Autonomes et Groupes Locaux Autonomes court-circuitent les
# niveaux intermédiaires : leur chaîne est `[layer, "national"]`.
class Event::Approval < ApplicationRecord
  LAYERS = %w[groupe_local district region national].freeze

  self.demodulized_route_keys = true

  ### ASSOCIATIONS

  belongs_to :application, class_name: "Event::Application"
  belongs_to :approver, class_name: "Person", optional: true

  has_one :participation, through: :application
  has_one :event, through: :participation

  ### VALIDATIONS

  validates :layer, inclusion: {in: LAYERS},
    uniqueness: {scope: :application_id, case_sensitive: false}
  validates :approved, exclusion: {in: [nil]}
  validates :rejected, exclusion: {in: [nil]}
  validate  :not_approved_and_rejected

  ### SCOPES

  scope :pending,  -> { where(approved: false, rejected: false) }
  scope :approved, -> { where(approved: true) }
  scope :rejected, -> { where(rejected: true) }

  ### INSTANCE

  def approvee
    participation&.person
  end

  def status
    return :approved if approved?
    return :rejected if rejected?

    :pending
  end

  def layer_class
    case layer
    when "groupe_local" then Group::GroupeLocal
    when "district"     then Group::District
    when "region"       then Group::RegionEeds
    when "national"     then Group::National
    end
  end

  ### CLASS METHODS

  class << self
    # Liste les approbations en attente pour un groupe-layer donné.
    # Filtre les candidats dont le primary_group est dans le sous-arbre.
    def pending_for(layer_group)
      class_name_layer = Eeds::ApprovalChain::LAYER_FOR_CLASS[layer_group.class.name] ||
        layer_group.class.name.demodulize.underscore
      joins(application: :participation)
        .joins("INNER JOIN people ON event_participations.participant_id = people.id AND " \
               "event_participations.participant_type = 'Person'")
        .joins("INNER JOIN groups primary_groups ON people.primary_group_id = primary_groups.id")
        .where("primary_groups.lft >= :lft AND primary_groups.rgt <= :rgt",
          lft: layer_group.lft, rgt: layer_group.rgt)
        .where(layer: class_name_layer, approved: false, rejected: false)
    end

    # Tri SQL stable par ordre des couches.
    def order_by_layer
      statement = +"CASE layer "
      LAYERS.each_with_index { |l, i| statement << "WHEN '#{l}' THEN #{i} " }
      statement << "END"
      order(Arel.sql(statement))
    end
  end

  private

  def not_approved_and_rejected
    return unless approved? && rejected?

    errors.add(:base, "ne peut pas être à la fois approuvée et rejetée")
  end
end
