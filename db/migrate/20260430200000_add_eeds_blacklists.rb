# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

class AddEedsBlacklists < ActiveRecord::Migration[8.0]
  def change
    create_table :eeds_blacklists do |t|
      t.string :first_name
      t.string :last_name
      t.string :matricule_scout
      t.string :email
      t.string :phone_number
      t.string :reason
      t.string :reference_name,         null: false
      t.string :reference_phone_number, null: false
      t.references :created_by, foreign_key: {to_table: :people}
      t.timestamps
    end

    add_index :eeds_blacklists, [:first_name, :last_name]
    add_index :eeds_blacklists, :email
    add_index :eeds_blacklists, :matricule_scout
  end
end
