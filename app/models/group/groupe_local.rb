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

  class ChefGroupeAdjoint < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
  end

  class SecretaireLocal < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
  end

  class TresorierLocal < ::Role
    self.permissions = [:layer_and_below_read, :finance, :contact_data]
  end

  class RespMateriel < ::Role
    self.permissions = [:group_read]
  end

  class RespParents < ::Role
    self.permissions = [:group_read]
  end

  roles ChefGroupe,
    ChefGroupeAdjoint,
    SecretaireLocal,
    TresorierLocal,
    RespMateriel,
    RespParents
end
