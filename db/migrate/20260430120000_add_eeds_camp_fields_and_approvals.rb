# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

class AddEedsCampFieldsAndApprovals < ActiveRecord::Migration[8.0]
  def change
    change_table :events, bulk: true do |t|
      # Niveaux d'approbation requis pour un camp EEDS
      t.boolean :requires_approval_groupe_local, null: false, default: false
      t.boolean :requires_approval_district,    null: false, default: false
      t.boolean :requires_approval_region,      null: false, default: false
      t.boolean :requires_approval_national,    null: false, default: false

      # Participants attendus par branche × genre (F = filles, M = garçons)
      t.integer :expected_participants_jiwu_f
      t.integer :expected_participants_jiwu_m
      t.integer :expected_participants_lawtan_f
      t.integer :expected_participants_lawtan_m
      t.integer :expected_participants_toor_toor_f
      t.integer :expected_participants_toor_toor_m
      t.integer :expected_participants_menneef_f
      t.integer :expected_participants_menneef_m
      t.integer :expected_participants_encadrement_f
      t.integer :expected_participants_encadrement_m

      # Lieu du camp
      t.string  :camp_location
      t.string  :camp_address
      t.string  :camp_coordinates
      t.string  :camp_emergency_phone
      t.string  :camp_owner

      # État administratif EEDS
      t.boolean :camp_submitted,                  null: false, default: false
      t.boolean :parental_authorizations_collected, null: false, default: false
      t.boolean :assurance_validated,             null: false, default: false
      t.date    :camp_days_count_validated_on
    end

    create_table :event_approvals do |t|
      t.integer  :application_id, null: false
      t.string   :layer,          null: false
      t.boolean  :approved,       null: false, default: false
      t.boolean  :rejected,       null: false, default: false
      t.text     :comment
      t.datetime :approved_at
      t.integer  :approver_id
      t.timestamps
    end

    add_index :event_approvals, :application_id
    add_index :event_approvals, [:application_id, :layer], unique: true
  end
end
