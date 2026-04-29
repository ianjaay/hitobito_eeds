# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Branche Jiwu wi (5 à 11 ans). Unité = Mbootaay, sous-unité = sizaine.
class Group::Mbootaay < Group
  self.event_types = [Event, Event::Camp]

  BRANCH_COLOR = "#fdef42"
  BRANCH_COLOR_NAME = "jaune"

  def self.branch_color = BRANCH_COLOR
  def self.branch_color_name = BRANCH_COLOR_NAME

  class Njiit < ::Role
    self.permissions = [:group_full]
  end

  class Reefaan < ::Role
    self.permissions = [:group_read]
  end

  class ChefSizaine < ::Role
    self.permissions = [:group_read]
  end

  class Caat < ::Role
    self.permissions = []
    self.visible_from_above = false
  end

  roles Njiit, Reefaan, ChefSizaine, Caat

  self.standard_role = Caat
end
