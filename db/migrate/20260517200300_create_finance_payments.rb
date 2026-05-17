# frozen_string_literal: true

# Versement/paiement effectué sur une obligation
class CreateFinancePayments < ActiveRecord::Migration[6.1]
  def change
    create_table :finance_payments do |t|
      t.references :obligation, null: false, foreign_key: { to_table: :finance_obligations }
      t.references :enregistre_par, null: false, foreign_key: { to_table: :people }

      t.integer :montant, null: false
      t.string  :modalite, null: false, default: "Cash"  # Cash, Virement, Mobile, Autre
      t.string  :statut, null: false, default: "enregistre"  # enregistre, valide, annule
      t.string  :reference_externe                       # numéro de transaction externe
      t.text    :commentaire

      t.datetime :valide_at

      t.timestamps
    end

    add_index :finance_payments, :statut
    add_index :finance_payments, :modalite
  end
end
