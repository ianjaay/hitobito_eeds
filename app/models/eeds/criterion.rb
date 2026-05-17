# frozen_string_literal: true

# Critère de validation pour un brevet MËN-MËN.
# Chaque QualificationKind de catégorie 'menmen' a plusieurs critères
# que le jeune doit remplir (partiellement ou totalement).
class Eeds::Criterion < ApplicationRecord
  self.table_name = "eeds_criteria"

  belongs_to :qualification_kind, class_name: "::QualificationKind"

  validates :label, presence: true
  validates :position, presence: true, numericality: { only_integer: true }

  default_scope { order(:position) }
end
