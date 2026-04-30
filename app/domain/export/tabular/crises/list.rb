# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

module Export::Tabular::Crises
  class List < Export::Tabular::Base
    self.model_class = ::Crisis
    self.row_class   = Export::Tabular::Crises::Row

    def attributes
      [:created_at, :group_name, :kind, :severity, :status, :creator_name,
        :acknowledged_at, :acknowledged_by_name, :completed_at, :completed_by_name,
        :description]
    end
  end
end
