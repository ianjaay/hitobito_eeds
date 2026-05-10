#  Copyright (c) 2025, Éclaireuses et Éclaireurs du Sénégal.
#  Ajoute la région administrative sénégalaise sur les fiches membres.
#  Distincte de la "Région scoute" qui est gérée via la hiérarchie de groupes
#  (Group::Kantonalverband, libellée "Région EEDS").

class AddAdministrativeRegionToPeople < ActiveRecord::Migration[7.1]
  def change
    add_column :people, :administrative_region, :string
  end
end
