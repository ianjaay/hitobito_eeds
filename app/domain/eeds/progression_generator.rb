# frozen_string_literal: true

# Génère automatiquement les progressions JEEGO pour un jeune
# lorsqu'il rejoint une unité de branche (Woelfe/Pfadi/Pio/Rover).
#
# Usage :
#   Eeds::ProgressionGenerator.new(person, group).call
#
class Eeds::ProgressionGenerator
  GROUP_TYPE_TO_BRANCHE = {
    "Group::Woelfe" => "mbootaay",
    "Group::Pfadi"  => "kayon",
    "Group::Pio"    => "dental",
    "Group::Rover"  => "galle"
  }.freeze

  attr_reader :person, :group

  def initialize(person, group)
    @person = person
    @group  = group
  end

  def call
    return unless branche

    jeego_kinds.find_each do |qk|
      Eeds::Progression.find_or_create_by!(
        person: person,
        qualification_kind: qk,
        group: group
      ) do |p|
        p.status = :not_started
      end
    end
  end

  def branche
    @branche ||= resolve_branche
  end

  private

  def resolve_branche
    # Cherche dans le groupe lui-même ou ses ancêtres
    current = group
    while current
      branche = GROUP_TYPE_TO_BRANCHE[current.type]
      return branche if branche
      current = current.parent
    end
    nil
  end

  def jeego_kinds
    QualificationKind.jeego.for_branche(branche)
  end
end
