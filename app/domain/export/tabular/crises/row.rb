# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

module Export::Tabular::Crises
  class Row < Export::Tabular::Row
    def group_name             = entry.group&.to_s
    def creator_name           = entry.creator&.to_s
    def acknowledged_by_name   = entry.acknowledged_by&.to_s
    def completed_by_name      = entry.completed_by&.to_s
    def status                 = entry.status.to_s
  end
end
