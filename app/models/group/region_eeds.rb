# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Niveau Région (équivalent PBS Kantonalverband).
#
# Note : la classe est nommée `RegionEeds` (et non `Region`) pour éviter une
# collision STI avec `Group::Region` du wagon PBS.
class Group::RegionEeds < Group
  self.layer = true
  self.event_types = [Event, Event::Course, Event::Camp]

  children Group::District

  ### Rôles ###

  class CommissaireRegional < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
    self.two_factor_authentication_enforced = true
  end

  # Adjoints par branche
  class CommissaireRegionalAdjointJiwu < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
  end

  class CommissaireRegionalAdjointLawtan < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
  end

  class CommissaireRegionalAdjointToorToor < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
  end

  class CommissaireRegionalAdjointMenneef < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
  end

  # Adjoints thématiques
  class CommissaireRegionalAdjointFormation < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  class CommissaireRegionalAdjointCommunication < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  class CommissaireRegionalAdjointProgramme < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  # Équipe régionale
  class MembreEquipeRegionale < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  # Fonctions support
  class SecretaireRegional < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  class TresorierRegional < ::Role
    self.permissions = [:layer_and_below_read, :finance, :contact_data]
  end

  roles CommissaireRegional,
    CommissaireRegionalAdjointJiwu,
    CommissaireRegionalAdjointLawtan,
    CommissaireRegionalAdjointToorToor,
    CommissaireRegionalAdjointMenneef,
    CommissaireRegionalAdjointFormation,
    CommissaireRegionalAdjointCommunication,
    CommissaireRegionalAdjointProgramme,
    MembreEquipeRegionale,
    SecretaireRegional,
    TresorierRegional
end
