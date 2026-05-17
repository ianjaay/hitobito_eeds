# frozen_string_literal: true

class CreateMaasReceipts < ActiveRecord::Migration[6.1]
  def change
    create_table :maas_receipts do |t|
      t.references :membership_subscription, null: false, foreign_key: { to_table: :maas_membership_subscriptions }
      t.references :payment_transaction, null: false, foreign_key: { to_table: :maas_payment_transactions }
      t.references :member, null: false, foreign_key: { to_table: :people }
      t.string     :numero, null: false
      t.decimal    :montant, precision: 12, scale: 2, null: false
      t.string     :modalite, default: "Cash"
      t.string     :branche
      t.integer    :annee_campagne
      t.string     :groupe_nom
      t.datetime   :emis_at, null: false

      t.timestamps
    end

    add_index :maas_receipts, :numero, unique: true
  end
end
