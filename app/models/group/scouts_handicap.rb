# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Section « Scouts Handicap » (SMT) : structure transversale d'inclusion
# rattachée directement au National. Encadre les éclaireurs en situation de
# handicap et leurs encadreurs spécialisés.
class Group::ScoutsHandicap < Group
  self.layer = true

  ### Rôles ###

  class Coordinateur < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
    self.two_factor_authentication_enforced = true
  end

  class Encadreur < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  class Conseiller < ::Role
    self.permissions = [:group_read, :contact_data]
  end

  class Membre < ::Role
    self.permissions = [:group_read]
    self.visible_from_above = false
  end

  roles Coordinateur, Encadreur, Conseiller, Membre

  self.standard_role = Membre
end
