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

      resources :membership_fees, only: [:index, :edit] do
        member do
          patch :mark_paid
          patch :mark_exempted
          patch :cancel
        end
        collection do
          post :generate
          post :remind
        end
      end

      resources :membership_fee_rates

      resources :member_counts, only: [:index, :edit, :update] do
        collection { post :recompute }
      end
    end

    resources :censuses
  end
end
