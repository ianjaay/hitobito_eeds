# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Branche Lawtan wi (12 à 15 ans). Unité = Kayon, sous-unité = patrouille.
class Group::Kayon < Group
  BRANCH_COLOR = "#00853f"
  BRANCH_COLOR_NAME = "verte"

  def self.branch_color = BRANCH_COLOR
  def self.branch_color_name = BRANCH_COLOR_NAME

  class Njiit < ::Role
    self.permissions = [:group_full]
  end

  class Reefaan < ::Role
    self.permissions = [:group_read]
  end

  class ChefPatrouille < ::Role
    self.permissions = [:group_read]
  end

  class Arunga < ::Role
    self.permissions = []
    self.visible_from_above = false
  end

  roles Njiit, Reefaan, ChefPatrouille, Arunga

  self.standard_role = Arunga
end
