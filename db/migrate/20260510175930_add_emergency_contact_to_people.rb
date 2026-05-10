#  Copyright (c) 2025, Éclaireuses et Éclaireurs du Sénégal.
#  Ajoute le contact d'urgence (champs plats) sur la fiche personne.
#  Pour les vrais responsables légaux des mineurs, utiliser people_managers.

class AddEmergencyContactToPeople < ActiveRecord::Migration[7.1]
  def change
    add_column :people, :emergency_contact_name, :string
    add_column :people, :emergency_contact_phone, :string
    add_column :people, :emergency_contact_relation, :string
  end
end
