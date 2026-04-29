# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

class AddEedsPersonFields < ActiveRecord::Migration[8.0]
  def change
    change_table :people, bulk: true do |t|
      t.string  :matricule_scout
      t.string  :branche
      t.string  :unite
      t.date    :assurance_expiration
      t.text    :progression_badges
      t.string  :parent_contact_name
      t.string  :parent_contact_phone
      t.string  :parent_contact_email
      t.string  :profession
      t.text    :competences
    end

    add_index :people, :matricule_scout, unique: true, where: "matricule_scout IS NOT NULL"
    add_index :people, :branche
  end
end
