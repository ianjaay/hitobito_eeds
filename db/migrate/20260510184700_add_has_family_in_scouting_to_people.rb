# frozen_string_literal: true

# EEDS — Indicateur "a un membre de sa famille dans le scoutisme".
# Saisi manuellement à la création / édition de la fiche personne.
class AddHasFamilyInScoutingToPeople < ActiveRecord::Migration[7.1]
  def change
    add_column :people, :has_family_in_scouting, :boolean, default: false, null: false
  end
end
