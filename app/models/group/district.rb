# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Niveau District (équivalent PBS Region).
class Group::District < Group
  self.layer = true
  self.event_types = [Event, Event::Course, Event::Camp]

  children Group::GroupeLocal

  ### Rôles ###

  class CommissaireDistrict < ::Role
    self.permissions = [:layer_and_below_full, :contact_data, :approve_applications]
    self.two_factor_authentication_enforced = true
  end

  class CommissaireDistrictAdjoint < ::Role
    self.permissions = [:layer_and_below_full, :contact_data, :approve_applications]
  end

  # Responsables par branche pédagogique
  class RespBrancheJiwu < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  class RespBrancheLawtan < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  class RespBrancheToorToor < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  class RespBrancheMenneef < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  class SecretaireDistrict < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  class TresorierDistrict < ::Role
    self.permissions = [:layer_and_below_read, :finance, :contact_data]
  end

  roles CommissaireDistrict,
    CommissaireDistrictAdjoint,
    RespBrancheJiwu,
    RespBrancheLawtan,
    RespBrancheToorToor,
    RespBrancheMenneef,
    SecretaireDistrict,
    TresorierDistrict
end
