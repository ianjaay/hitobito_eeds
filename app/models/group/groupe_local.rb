# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Niveau opérationnel local (équivalent PBS Abteilung).
# Contient les unités pédagogiques par branche.
class Group::GroupeLocal < Group
  self.layer = true

  children Group::Mbootaay,
    Group::Kayon,
    Group::Nawka,
    Group::Galle

  ### Rôles ###

  class ChefGroupe < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
    self.two_factor_authentication_enforced = true
  end

  # Membres de la maîtrise locale (équipe d'encadrement)
  class MembreMaitrise < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  # Responsables d'unité par branche
  class RespUniteMbootaay < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  class RespUniteKayon < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  class RespUniteNawka < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  class RespUniteGalle < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  class SecretaireLocal < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  class TresorierLocal < ::Role
    self.permissions = [:layer_and_below_read, :finance, :contact_data]
  end

  roles ChefGroupe,
    MembreMaitrise,
    RespUniteMbootaay,
    RespUniteKayon,
    RespUniteNawka,
    RespUniteGalle,
    SecretaireLocal,
    TresorierLocal
end
