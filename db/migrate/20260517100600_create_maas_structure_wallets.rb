# frozen_string_literal: true

class CreateMaasStructureWallets < ActiveRecord::Migration[6.1]
  def change
    create_table :maas_structure_wallets do |t|
      t.integer  :structure_id,    null: false
      t.string   :structure_type,  null: false
      t.decimal  :balance,         null: false, default: 0, precision: 12, scale: 2
      t.decimal  :pending_balance, null: false, default: 0, precision: 12, scale: 2
      t.decimal  :total_collected, null: false, default: 0, precision: 12, scale: 2
      t.datetime :last_updated_at

      t.timestamps
    end

    add_index :maas_structure_wallets, [:structure_id, :structure_type], unique: true, name: "idx_maas_wallets_structure"
  end
end
