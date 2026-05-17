# frozen_string_literal: true

class CreateMaasMembershipSubscriptions < ActiveRecord::Migration[6.1]
  def change
    create_table :maas_membership_subscriptions do |t|
      t.references :membership_campaign, null: false, foreign_key: { to_table: :maas_membership_campaigns }
      t.references :membership_plan,     null: false, foreign_key: { to_table: :maas_membership_plans }
      t.integer    :member_id,           null: false
      t.integer    :group_id,            null: false
      t.string     :statut,              null: false, default: "en_attente"
      t.decimal    :montant_total,       null: false, precision: 10, scale: 2
      t.decimal    :montant_paye,        null: false, default: 0, precision: 10, scale: 2
      t.boolean    :assurance_active,    default: false
      t.string     :qr_token
      t.datetime   :expires_at

      t.timestamps
    end

    add_index :maas_membership_subscriptions, [:membership_campaign_id, :member_id], unique: true, name: "idx_maas_subs_campaign_member"
    add_index :maas_membership_subscriptions, :member_id
    add_index :maas_membership_subscriptions, :group_id
    add_index :maas_membership_subscriptions, :statut
    add_index :maas_membership_subscriptions, :qr_token, unique: true
  end
end
