# frozen_string_literal: true

class CreateMaasPaymentTransactions < ActiveRecord::Migration[6.1]
  def change
    create_table :maas_payment_transactions do |t|
      t.references :membership_subscription, null: false, foreign_key: { to_table: :maas_membership_subscriptions }
      t.string     :modalite,                null: false, default: "Cash"
      t.decimal    :montant,                 null: false, precision: 10, scale: 2
      t.string     :statut,                  null: false, default: "enregistre"
      t.string     :reference_manuelle
      t.text       :notes
      t.integer    :enregistre_par_id,       null: false
      t.datetime   :valide_at

      t.timestamps
    end

    add_index :maas_payment_transactions, :enregistre_par_id
    add_index :maas_payment_transactions, :statut
  end
end
