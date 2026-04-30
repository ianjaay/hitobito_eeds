# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

class AddEedsMembershipFees < ActiveRecord::Migration[8.0]
  def change
    create_table :eeds_membership_fees do |t|
      t.references :person, null: false, foreign_key: true, index: true
      t.references :group,  null: false, foreign_key: true, index: true
      t.integer    :year,         null: false
      t.string     :branche,      null: false # jiwu, lawtan, toor_toor, menneef, encadrement
      t.integer    :amount_cents, null: false, default: 0
      t.string     :currency,     null: false, default: "XOF"
      t.string     :status,       null: false, default: "pending"
      t.datetime   :paid_at
      t.string     :payment_method # cash, bank_transfer, mobile_money, other
      t.string     :reference
      t.text       :comment
      t.references :recorded_by, foreign_key: {to_table: :people}
      t.timestamps
    end

    add_index :eeds_membership_fees, [:person_id, :year], unique: true
    add_index :eeds_membership_fees, [:group_id, :year]
    add_index :eeds_membership_fees, :status

    create_table :eeds_membership_fee_rates do |t|
      t.integer :year,         null: false
      t.string  :branche,      null: false
      t.integer :amount_cents, null: false
      t.string  :currency,     null: false, default: "XOF"
      t.text    :description
      t.timestamps
    end

    add_index :eeds_membership_fee_rates, [:year, :branche], unique: true
  end
end
