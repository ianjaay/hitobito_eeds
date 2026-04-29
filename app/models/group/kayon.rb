# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Branche Lawtan wi (12 à 15 ans).
# Unité pédagogique = Kayon. Membres : Arunga. Encadrement : Njiit, Reefaan,
# Rambeen.
class Group::Kayon < Group
  # Couleur officielle de la branche Kayon (Lawtan wi) : verte.
  BRANCH_COLOR = "#00853f"
  BRANCH_COLOR_NAME = "verte"

  def self.branch_color = BRANCH_COLOR
  def self.branch_color_name = BRANCH_COLOR_NAME

  # Pas d'enfants en Phase 1 (les patrouilles/sizaines "Jiyon" arriveront en
  # Phase 2+).

  class Njiit < ::Role
    self.permissions = [:group_full]
  end

  class Reefaan < ::Role
    self.permissions = [:group_read]
  end

  class Rambeen < ::Role
    self.permissions = [:group_read]
  end

  class Arunga < ::Role
    self.permissions = []
    self.visible_from_above = false
  end

  roles Njiit, Reefaan, Rambeen, Arunga

  self.standard_role = Arunga
end
