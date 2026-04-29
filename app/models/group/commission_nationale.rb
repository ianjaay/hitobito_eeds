# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Commission Nationale (rattachée au National). Plusieurs commissions
# coexistent : formation, communication, relations internationales,
# inclusion, environnement, etc. Le thème est libre (porté par le `name`
# du groupe).
class Group::CommissionNationale < Group
  self.layer = false

  ### Rôles ###

  class CoordinateurCommission < ::Role
    self.permissions = [:group_full, :contact_data]
  end

  class MembreCommission < ::Role
    self.permissions = [:group_read]
  end

  class Encadreur < ::Role
    self.permissions = [:group_read, :contact_data]
  end

  class Conseiller < ::Role
    self.permissions = [:group_read]
  end

  roles CoordinateurCommission,
    MembreCommission,
    Encadreur,
    Conseiller

  self.standard_role = MembreCommission
end
