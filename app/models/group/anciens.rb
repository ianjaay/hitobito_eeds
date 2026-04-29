# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Structure « Anciens éclaireurs » : amicale des anciens membres, rattachée
# directement au National.
class Group::Anciens < Group
  self.layer = true

  ### Rôles ###

  class President < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
  end

  class MembreBureau < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  class Membre < ::Role
    self.permissions = [:group_read]
    self.visible_from_above = false
  end

  roles President, MembreBureau, Membre

  self.standard_role = Membre
end
