# frozen_string_literal: true

# Critères de validation pour chaque brevet MËN-MËN.
# Chaque QualificationKind de catégorie 'menmen' a N critères à remplir.
class CreateEedsCriteria < ActiveRecord::Migration[6.1]
  def change
    create_table :eeds_criteria do |t|
      t.references :qualification_kind, null: false, foreign_key: true
      t.string :label, null: false
      t.text :description
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :eeds_criteria,
              [:qualification_kind_id, :position],
              name: :idx_eeds_criteria_kind_pos
  end
end
