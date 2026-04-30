# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Habilitations CanCan pour la liste de signalement EEDS.
# Réservée aux administrateurs nationaux.
class BlacklistAbility < AbilityDsl::Base
  on(Blacklist) do
    permission(:admin).may(:show, :index, :create, :update, :destroy).all
  end
end
