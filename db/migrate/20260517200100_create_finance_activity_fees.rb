# frozen_string_literal: true

# Frais liés à une activité (event, camp, formation, adhésion, etc.)
class CreateFinanceActivityFees < ActiveRecord::Migration[6.1]
  def change
    create_table :finance_activity_fees do |t|
      # Lien polymorphe vers la source (Event, Maas::MembershipCampaign, etc.)
      t.string  :feeable_type, null: false           # "Event", "Maas::MembershipCampaign"
      t.integer :feeable_id, null: false

      t.string  :libelle, null: false                 # ex: "Frais d'inscription", "Cotisation Mbootaay"
      t.string  :categorie, null: false, default: "inscription"  # inscription, transport, uniforme, cotisation, autre
      t.integer :montant, null: false                 # montant en FCFA
      t.integer :montant_assurance, default: 0        # assurance optionnelle
      t.integer :minimum_partiel                      # versement partiel minimum
      t.string  :branche                              # nil = tous, sinon branche spécifique

      # Groupe propriétaire du frais
      t.references :group, null: false, foreign_key: { to_table: :groups }

      t.boolean :obligatoire, default: true           # paiement requis ?
      t.boolean :actif, default: true                 # frais actif ?
      t.string  :description

      t.timestamps
    end

    add_index :finance_activity_fees, [:feeable_type, :feeable_id]
    add_index :finance_activity_fees, :categorie
    add_index :finance_activity_fees, :actif
  end
end
