# frozen_string_literal: true

# Ajoute les colonnes `category` et `metadata` à qualification_kinds
# pour distinguer les JEEGO (progression collective) des MËN-MËN (brevets individuels)
# et stocker les métadonnées pédagogiques (branche, domaine, niveau, prérequis).
class AddCategoryAndMetadataToQualificationKinds < ActiveRecord::Migration[6.1]
  def change
    add_column :qualification_kinds, :category, :string
    add_column :qualification_kinds, :metadata, :jsonb, default: {}
    add_column :qualification_kinds, :key, :string

    add_index :qualification_kinds, :category
    add_index :qualification_kinds, :key, unique: true
  end
end
