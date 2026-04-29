# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# District Autonome : district rattaché directement au National (sans Région
# intermédiaire). Mêmes responsabilités fonctionnelles que Group::District.
class Group::DistrictAutonome < Group
  self.layer = true

  children Group::GroupeLocal

  ### Rôles ###

  class CommissaireDistrict < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
    self.two_factor_authentication_enforced = true
  end

  class CommissaireDistrictAdjoint < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
  end

  class SecretaireDistrict < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  class TresorierDistrict < ::Role
    self.permissions = [:layer_and_below_read, :finance, :contact_data]
  end

  class RespFormation < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  class RespAnimation < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  roles CommissaireDistrict,
    CommissaireDistrictAdjoint,
    SecretaireDistrict,
    TresorierDistrict,
    RespFormation,
    RespAnimation
end
