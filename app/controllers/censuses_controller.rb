# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

# Recensements EEDS. Géré nationalement (un par année).
class CensusesController < CrudController
  self.permitted_attrs = [:year, :start_at, :finish_at]

  before_action :authorize_action

  private

  def authorize_action
    authorize!((action_name == "index" ? :index : :show), Census.new)
  end
end
