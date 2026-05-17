# frozen_string_literal: true

class CreateMaasMembershipPlans < ActiveRecord::Migration[6.1]
  def change
    create_table :maas_membership_plans do |t|
      t.references :membership_campaign, null: false, foreign_key: { to_table: :maas_membership_campaigns }
      t.string     :branche,             null: false
      t.decimal    :montant,             null: false, precision: 10, scale: 2
      t.boolean    :assurance_incluse,   default: false
      t.decimal    :montant_assurance,   precision: 10, scale: 2
      t.decimal    :minimum_partiel,     precision: 10, scale: 2

      t.timestamps
    end

    add_index :maas_membership_plans, [:membership_campaign_id, :branche], unique: true, name: "idx_maas_plans_campaign_branche"
  end
end
