# frozen_string_literal: true

# Obligation de paiement d'un participant pour un frais donné
class CreateFinanceObligations < ActiveRecord::Migration[6.1]
  def change
    create_table :finance_obligations do |t|
      t.references :activity_fee, null: false, foreign_key: { to_table: :finance_activity_fees }
      t.references :person, null: false, foreign_key: { to_table: :people }   # le payeur

      # Lien optionnel vers la participation (quand c'est un event)
      t.references :event_participation, foreign_key: { to_table: :event_participations }

      # Lien optionnel vers l'adhésion MAAS (rétrocompatibilité)
      t.references :membership_subscription, foreign_key: { to_table: :maas_membership_subscriptions }

      t.references :group, null: false, foreign_key: { to_table: :groups }

      t.integer :montant_total, null: false
      t.integer :montant_paye, null: false, default: 0
      t.string  :statut, null: false, default: "en_attente"  # en_attente, partiel, valide, expire, annule

      t.boolean :assurance_active, default: false
      t.datetime :expires_at

      t.timestamps
    end

    add_index :finance_obligations, :statut
    add_index :finance_obligations, [:activity_fee_id, :person_id], unique: true,
              name: "idx_finance_obligations_fee_person"
  end
end
