# frozen_string_literal: true

# Page d'administration pour configurer les accès aux fonctionnalités EEDS
# par type de rôle. Accessible uniquement aux administrateurs (permission :admin).
class Admin::FeaturePermissionsController < ApplicationController
  skip_authorization_check
  before_action :authorize_admin

  # GET /admin/feature_permissions
  def index
    @features = Admin::FeaturePermission::FEATURES
    @actions  = Admin::FeaturePermission::ACTIONS
    @matrix = Admin::FeaturePermission.permission_matrix

    # Construire la liste des rôles avec labels traduits
    all_types = Role.all_types.sort_by(&:name)
    @role_data = all_types.map do |t|
      group_class = t.name.split("::")[0..1].join("::").constantize rescue nil
      group_label = group_class&.label || t.name.split("::")[1]
      {
        type_name: t.name,
        role_label: t.model_name.human,
        group_label: group_label,
        group_key: t.name.split("::")[0..1].join("::")
      }
    end

    # Grouper les rôles par type de groupe (avec label traduit)
    @grouped_roles = @role_data.group_by { |r| r[:group_key] }
  end

  # PATCH /admin/feature_permissions/update_all
  def update_all
    permissions_params = params[:permissions] || {}

    ActiveRecord::Base.transaction do
      # Supprimer toutes les entrées existantes et recréer
      Admin::FeaturePermission.delete_all

      permissions_params.each do |role_type, features|
        features.each do |feature_action, allowed_value|
          feature, action = feature_action.split(":")
          Admin::FeaturePermission.create!(
            role_type: role_type,
            feature: feature,
            action: action,
            allowed: allowed_value == "1"
          )
        end
      end
    end

    redirect_to admin_feature_permissions_path,
                notice: "Configuration des accès mise à jour avec succès."
  end

  private

  def authorize_admin
    context = AbilityDsl::UserContext.new(current_user)
    unless context.all_permissions.include?(:admin)
      raise CanCan::AccessDenied.new("Accès réservé aux administrateurs.", :manage, :all)
    end
  end
end
