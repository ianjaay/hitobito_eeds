# frozen_string_literal: true

# Table centrale de suivi pédagogique : chaque ligne représente la progression
# d'un jeune sur un JEEGO ou MËN-MËN donné.
class CreateEedsProgressions < ActiveRecord::Migration[6.1]
  def change
    create_table :eeds_progressions do |t|
      t.references :person, null: false, foreign_key: { to_table: :people }
      t.references :qualification_kind, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true
      t.integer :status, default: 0, null: false
      t.references :validated_by, foreign_key: { to_table: :people }
      t.datetime :validated_at
      t.text :notes
      t.references :event, foreign_key: true
      t.jsonb :criteria_met, default: []
      t.timestamps
    end

    add_index :eeds_progressions,
              [:person_id, :qualification_kind_id],
              unique: true,
              name: :idx_eeds_prog_person_qual

    add_index :eeds_progressions,
              [:group_id, :status],
              name: :idx_eeds_prog_group_status
  end
end
