# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

class AddEedsCrises < ActiveRecord::Migration[8.0]
  def change
    create_table :eeds_crises do |t|
      t.references :creator, null: false, foreign_key: {to_table: :people}
      t.references :group,   null: false, foreign_key: true
      t.string  :kind,        null: false # accident, abus, conflit, sante, autre
      t.string  :severity,    null: false, default: "medium" # low, medium, high, critical
      t.text    :description
      t.boolean :acknowledged, null: false, default: false
      t.boolean :completed,    null: false, default: false
      t.datetime :acknowledged_at
      t.datetime :completed_at
      t.references :acknowledged_by, foreign_key: {to_table: :people}
      t.references :completed_by,    foreign_key: {to_table: :people}
      t.timestamps
    end

    add_index :eeds_crises, :kind
    add_index :eeds_crises, :severity
  end
end
