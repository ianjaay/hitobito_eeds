# frozen_string_literal: true

Rails.application.routes.draw do
  extend LanguageRouteScope

  language_scope do
    # Administration centrale des JEEGO et MËN-MËN (Paramètres)
    resources :eeds_progression_badges, controller: "eeds/admin_progressions"

    # ── ADMIN — Configuration des accès aux fonctionnalités ──
    namespace :admin do
      resources :feature_permissions, only: [:index] do
        collection do
          patch :update_all
        end
      end
    end

    # ── MAAS — Module d'Adhésion Annuelle Solidaire ──

    # Admin national : gestion des campagnes et plans
    namespace :maas do
      resources :campagnes, controller: "campagnes" do
        member do
          patch :activate
          patch :fermer
          patch :archiver
        end
        resources :plans, controller: "plans", except: [:index, :show]
      end

      # Vérification QR (public)
      get "verifier/:token", to: "verifier#verify", as: :verifier
    end

    resources :groups do
      resource :excel_imports, only: [:new, :create], controller: "eeds/excel_imports" do
        member do
          post :preview
          post :template
        end
      end

      # Vue Responsable — group-level progression overview
      resources :group_progressions, only: [:index], controller: "eeds/group_progressions"

      # MAAS — Adhésions locales (responsable de groupe)
      namespace :maas do
        resources :adhesions, controller: "adhesions" do
          member do
            get :versement
            post :create_versement
          end
        end
      end

      # ── FINANCE — Module de gestion financière des activités ──
      namespace :finance do
        resources :dashboard, only: [:index], controller: "dashboard"

        resources :activity_fees do
          resources :obligations, controller: "obligations" do
            member do
              get :versement
              post :create_versement
            end
          end
        end
      end

      # Finance — Vue financière d'un événement
      resources :events, only: [] do
        resources :finances, only: [:index], controller: "finance/event_finances"
      end

      resources :people, only: [] do
        # MAAS — Adhésions du membre (onglet profil)
        resources :maas_adhesions, only: [:index], controller: "maas/person_adhesions"

        # MAAS — Reçus PDF téléchargeables
        resources :maas_receipts, only: [:show], controller: "maas/receipts"

        # FINANCE — Finances du membre (onglet profil)
        resources :finances, only: [:index], controller: "finance/person_finances"

        # FINANCE — Reçus PDF téléchargeables
        resources :finance_receipts, only: [:show], controller: "finance/receipts"

        resources :progressions, only: [:index, :show, :new, :create, :edit, :update],
                                 controller: "eeds/progressions" do
          member do
            patch :validate_progression
            patch :request_rework
            patch :start
            post :add_comment
          end
        end
      end
    end
  end
end
