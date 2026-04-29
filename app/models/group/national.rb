# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Niveau National (équivalent PBS Bund). Racine fonctionnelle de l'arbre EEDS
# (enregistrée comme `root_type` dans HitobitoEeds::Wagon).
class Group::National < Group
  self.layer = true

  children Group::RegionEeds,
    Group::DistrictAutonome,
    Group::GroupeLocalAutonome

  ### Rôles ###

  class President < ::Role
    self.permissions = [:layer_and_below_full, :admin, :contact_data]
    self.two_factor_authentication_enforced = true
  end

  class CommissaireGeneral < ::Role
    self.permissions = [:layer_and_below_full, :admin, :contact_data]
    self.two_factor_authentication_enforced = true
  end

  class CommissaireInternational < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
    self.two_factor_authentication_enforced = true
  end

  class TresorierNational < ::Role
    self.permissions = [:layer_and_below_full, :finance, :contact_data]
    self.two_factor_authentication_enforced = true
  end

  class SecretaireGeneral < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
    self.two_factor_authentication_enforced = true
  end

  class RespCommunication < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  class RespDigital < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  class RespFormation < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  class RespProgrammeJeunes < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  roles President,
    CommissaireGeneral,
    CommissaireInternational,
    TresorierNational,
    SecretaireGeneral,
    RespCommunication,
    RespDigital,
    RespFormation,
    RespProgrammeJeunes
end
