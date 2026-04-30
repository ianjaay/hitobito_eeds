# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

module Export::Tabular::MemberCounts
  class List < Export::Tabular::Base
    self.model_class = ::MemberCount
    self.row_class   = Export::Tabular::MemberCounts::Row

    def attributes
      base = [:year, :group_name]
      counts = ::MemberCount::CATEGORIES.flat_map do |c|
        ::MemberCount::GENDERS.map { |g| :"#{c}_#{g}" }
      end
      base + counts + [:total]
    end
  end
end
