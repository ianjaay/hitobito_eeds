# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

module Export::Tabular::Blacklists
  class List < Export::Tabular::Base
    self.model_class = ::Blacklist
    self.row_class   = Export::Tabular::Blacklists::Row

    def attributes
      [:last_name, :first_name, :matricule_scout, :email, :phone_number,
        :reason, :reference_name, :reference_phone_number, :created_at]
    end
  end
end
