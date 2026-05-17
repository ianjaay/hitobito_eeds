# frozen_string_literal: true

# Répartition financière vers les structures hiérarchiques
class CreateFinanceDistributions < ActiveRecord::Migration[6.1]
  def change
    create_table :finance_distributions do |t|
      t.references :payment, null: false, foreign_key: { to_table: :finance_payments }
      t.references :structure, null: false, foreign_key: { to_table: :groups }

      t.string  :structure_type, null: false  # local, district, region, national
      t.decimal :pourcentage, precision: 5, scale: 2, null: false
      t.integer :montant, null: false
      t.string  :statut, null: false, default: "calcule"  # calcule, credite, reverse

      t.timestamps
    end

    add_index :finance_distributions, :structure_type
    add_index :finance_distributions, :statut
  end
end
