# frozen_string_literal: true

class CreateMaasMembershipCampaigns < ActiveRecord::Migration[6.1]
  def change
    create_table :maas_membership_campaigns do |t|
      t.string   :annee,           null: false
      t.datetime :date_ouverture,  null: false
      t.datetime :date_fermeture,  null: false
      t.string   :statut,          null: false, default: "brouillon"
      t.integer  :created_by_id
      t.text     :description

      t.timestamps
    end

    add_index :maas_membership_campaigns, :annee, unique: true
    add_index :maas_membership_campaigns, :statut
    add_index :maas_membership_campaigns, :created_by_id
  end
end
