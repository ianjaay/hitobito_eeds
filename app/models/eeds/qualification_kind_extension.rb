# frozen_string_literal: true

# Extension du modèle QualificationKind de hitobito core.
# Ajoute les scopes et méthodes pour distinguer JEEGO (progression collective)
# et MËN-MËN (brevets individuels), et accéder aux métadonnées pédagogiques.
module Eeds::QualificationKindExtension
  extend ActiveSupport::Concern

  included do
    has_one_attached :badge_image do |attachable|
      attachable.variant :thumb, resize_to_fill: [64, 64]
      attachable.variant :medium, resize_to_fill: [128, 128]
    end

    has_many :criteria, class_name: "Eeds::Criterion",
                        foreign_key: :qualification_kind_id,
                        dependent: :destroy

    has_many :progressions, class_name: "Eeds::Progression",
                            foreign_key: :qualification_kind_id,
                            dependent: :restrict_with_error

    scope :jeego, -> { where(category: "jeego") }
    scope :menmen, -> { where(category: "menmen") }
    scope :for_branche, ->(branche) { where("metadata->>'branche' = ?", branche.to_s) }
    scope :for_domaine, ->(domaine) { where("metadata->>'domaine' = ?", domaine.to_s) }
  end

  def jeego?
    category == "jeego"
  end

  def menmen?
    category == "menmen"
  end

  def branche
    metadata&.dig("branche")
  end

  def domaine
    metadata&.dig("domaine")
  end

  def niveau
    metadata&.dig("niveau")
  end

  def prerequisite
    prereq_key = metadata&.dig("prerequisite")
    return nil if prereq_key.blank?

    ::QualificationKind.find_by(key: prereq_key)
  end

  def minimum_criteria
    metadata&.dig("minimum_criteria") || criteria.count
  end
end
