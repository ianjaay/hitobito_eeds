# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Branche Toor-Toor wi (16 à 18 ans).
# Unité pédagogique = Ñawka (aussi appelée Dental). Membres : Jàmbaar.
# Encadrement : Njiit, Reefaan, Rambeen.
#
# Note : la classe est nommée `Nawka` (sans diacritique) pour rester ASCII-safe
# côté SGBD (colonne `type` STI) et URLs. Le libellé affiché « Ñawka » est
# fourni par les fichiers de locale.
class Group::Nawka < Group
  # Couleur officielle de la branche Ñawka (Toor-Toor wi) : blanche.
  BRANCH_COLOR = "#ffffff"
  BRANCH_COLOR_NAME = "blanche"

  def self.branch_color = BRANCH_COLOR
  def self.branch_color_name = BRANCH_COLOR_NAME

  # Pas d'enfants en Phase 1 (les clans "Fedde" arriveront en Phase 2+).

  class Njiit < ::Role
    self.permissions = [:group_full]
  end

  class Reefaan < ::Role
    self.permissions = [:group_read]
  end

  class Rambeen < ::Role
    self.permissions = [:group_read]
  end

  class Jambaar < ::Role
    self.permissions = []
    self.visible_from_above = false
  end

  roles Njiit, Reefaan, Rambeen, Jambaar

  self.standard_role = Jambaar
end
