# frozen_string_literal: true

# Reçu de paiement (PDF)
class CreateFinanceReceipts < ActiveRecord::Migration[6.1]
  def change
    create_table :finance_receipts do |t|
      t.references :payment, null: false, foreign_key: { to_table: :finance_payments }
      t.references :obligation, null: false, foreign_key: { to_table: :finance_obligations }
      t.references :person, null: false, foreign_key: { to_table: :people }

      t.string  :numero, null: false
      t.integer :montant, null: false
      t.string  :libelle_activite                   # descriptif de l'activité
      t.string  :modalite
      t.string  :groupe_nom
      t.integer :annee

      t.datetime :emis_at, null: false

      t.timestamps
    end

    add_index :finance_receipts, :numero, unique: true
    add_index :finance_receipts, :annee
  end
end
