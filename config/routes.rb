# frozen_string_literal: true

#  Copyright (c) 2026, Éclaireuses et Éclaireurs du Sénégal. This file is part
#  of hitobito_eeds and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://www.gnu.org/licenses/agpl-3.0.html.

Rails.application.routes.draw do
  extend LanguageRouteScope

  language_scope do
    resource :eeds_member_imports,
      only: [:new, :create],
      controller: "eeds_member_imports" do
      post :preview, on: :collection
    end

    resources :groups, only: [] do
      resources :events, only: [] do
        scope module: "event" do
          resources :participations, only: [] do
            resources :approvals, only: [:new, :create, :index]
            get "approvals" => "approvals#new" # route required for language switch
          end
          resources :approvals, only: [:index]
        end
      end
    end
  end
end
