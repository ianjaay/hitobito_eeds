# frozen_string_literal: true

# Portefeuille financier par structure (solde cumulé)
class CreateFinanceWallets < ActiveRecord::Migration[6.1]
  def change
    create_table :finance_wallets do |t|
      t.references :structure, null: false, foreign_key: { to_table: :groups }
      t.string  :structure_type, null: false  # local, district, region, national

      t.integer :balance, null: false, default: 0
      t.integer :total_collected, null: false, default: 0
      t.datetime :last_updated_at

      t.timestamps
    end

    add_index :finance_wallets, [:structure_id, :structure_type], unique: true,
              name: "idx_finance_wallets_structure"
  end
end
