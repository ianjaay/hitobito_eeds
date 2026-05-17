# frozen_string_literal: true

# Journal d'audit pour les progressions pédagogiques.
# Chaque changement de statut, ajout de commentaire ou validation
# de critère est tracé avec l'identité de l'acteur.
class Eeds::ProgressionLog < ApplicationRecord
  self.table_name = "eeds_progression_logs"

  belongs_to :eeds_progression, class_name: "Eeds::Progression"
  belongs_to :actor, class_name: "::Person"

  validates :action, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
