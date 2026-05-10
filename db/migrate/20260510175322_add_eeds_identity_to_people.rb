#  Copyright (c) 2025, Éclaireuses et Éclaireurs du Sénégal.
#  Ajoute les attributs d'identité spécifiques EEDS.

class AddEedsIdentityToPeople < ActiveRecord::Migration[7.1]
  def change
    add_column :people, :birthplace, :string
    add_column :people, :nationality, :string, default: "Sénégalaise"
  end
end
