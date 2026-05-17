# frozen_string_literal: true

# Journal d'audit : trace chaque modification de statut, commentaire ou
# validation de critère sur une progression.
class CreateEedsProgressionLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :eeds_progression_logs do |t|
      t.references :eeds_progression, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: { to_table: :people }
      t.string :action, null: false
      t.string :old_value
      t.string :new_value
      t.text :notes
      t.datetime :created_at, null: false
    end

    add_index :eeds_progression_logs,
              [:eeds_progression_id, :created_at],
              name: :idx_eeds_logs_prog_date
  end
end
