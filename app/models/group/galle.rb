# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Branche Meññeef mi (18+). Unité = Gàlle, sous-unité = équipe.
class Group::Galle < Group
  BRANCH_COLOR = "#e31b23"
  BRANCH_COLOR_NAME = "rouge"

  def self.branch_color = BRANCH_COLOR
  def self.branch_color_name = BRANCH_COLOR_NAME

  class Njiit < ::Role
    self.permissions = [:group_full]
  end

  class Reefaan < ::Role
    self.permissions = [:group_read]
  end

  class ChefEquipe < ::Role
    self.permissions = [:group_read]
  end

  class Mawdo < ::Role
    self.permissions = []
    self.visible_from_above = false
  end

  roles Njiit, Reefaan, ChefEquipe, Mawdo

  self.standard_role = Mawdo
end
