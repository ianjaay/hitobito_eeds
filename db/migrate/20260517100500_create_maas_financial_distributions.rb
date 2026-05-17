# frozen_string_literal: true

class CreateMaasFinancialDistributions < ActiveRecord::Migration[6.1]
  def change
    create_table :maas_financial_distributions do |t|
      t.references :payment_transaction, null: false, foreign_key: { to_table: :maas_payment_transactions }
      t.string     :structure_type,      null: false
      t.integer    :structure_id,        null: false
      t.decimal    :pourcentage,         null: false, precision: 5, scale: 2
      t.decimal    :montant,             null: false, precision: 10, scale: 2
      t.string     :statut,              null: false, default: "calcule"

      t.timestamps
    end

    add_index :maas_financial_distributions, :structure_id
    add_index :maas_financial_distributions, :statut
  end
end
