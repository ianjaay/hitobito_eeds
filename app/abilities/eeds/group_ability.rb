# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Expose the Camps tab in the group sub-navigation: any authenticated user
# may read the camps list of a group (visibility of individual camps still
# governed by EventAbility).
module Eeds::GroupAbility
  extend ActiveSupport::Concern

  included do
    on(Group) do
      permission(:any).may(:"index_event/camps").all
    end
  end
end
