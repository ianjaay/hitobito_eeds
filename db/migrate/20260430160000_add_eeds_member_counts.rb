# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

class AddEedsMemberCounts < ActiveRecord::Migration[8.0]
  CATEGORIES = %i[jiwu lawtan toor_toor menneef encadrement].freeze

  def change
    create_table :eeds_censuses do |t|
      t.integer :year,      null: false
      t.date    :start_at,  null: false
      t.date    :finish_at
      t.timestamps
    end
    add_index :eeds_censuses, :year, unique: true

    create_table :eeds_member_counts do |t|
      t.references :group,   null: false, foreign_key: true, index: true
      t.references :census,  foreign_key: {to_table: :eeds_censuses}
      t.integer    :year,    null: false
      CATEGORIES.each do |c|
        t.integer :"#{c}_f", default: 0, null: false
        t.integer :"#{c}_m", default: 0, null: false
        t.integer :"#{c}_u", default: 0, null: false # genre non renseigné
      end
      t.timestamps
    end
    add_index :eeds_member_counts, [:group_id, :year], unique: true
  end
end
