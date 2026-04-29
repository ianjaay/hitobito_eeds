# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Niveau Région (équivalent PBS Kantonalverband).
# Une Région EEDS regroupe plusieurs Districts au sein d'une des 14 régions
# administratives du Sénégal.
#
# Note : la classe est nommée `RegionEeds` (et non `Region`) pour éviter une
# collision STI avec `Group::Region` du wagon PBS si les deux wagons devaient
# un jour cohabiter. Le libellé affiché « Région » est fourni par les fichiers
# de locale.
class Group::RegionEeds < Group
  self.layer = true

  children Group::District

  ### Rôles ###

  class CommissaireRegional < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
    self.two_factor_authentication_enforced = true
  end

  class CommissaireRegionalAdjoint < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
  end

  class TresorierRegional < ::Role
    self.permissions = [:layer_and_below_read, :finance, :contact_data]
  end

  class RespFormation < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  class RespProgramme < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  class RespCommunication < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  roles CommissaireRegional,
    CommissaireRegionalAdjoint,
    TresorierRegional,
    RespFormation,
    RespProgramme,
    RespCommunication
end
