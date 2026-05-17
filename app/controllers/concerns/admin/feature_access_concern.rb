# frozen_string_literal: true

# Concern inclus dans les controllers EEDS pour vérifier les accès configurables.
# Consulte la table admin_feature_permissions avant de laisser AbilityDsl décider.
#
# Usage dans un controller :
#   include Admin::FeatureAccessConcern
#   before_action -> { check_feature_access!("finance") }
module Admin::FeatureAccessConcern
  extend ActiveSupport::Concern

  included do
    helper_method :feature_allowed?
  end

  private

  # Vérifie si l'utilisateur courant a accès à la fonctionnalité.
  # Lève CanCan::AccessDenied si une entrée refuse explicitement.
  # Si aucune config → laisse passer (fallback AbilityDsl).
  def check_feature_access!(feature)
    return if current_user&.root?

    action = feature_action_name
    group = @group if defined?(@group)

    unless Admin::FeaturePermission.allowed?(current_user, feature, action, group)
      raise CanCan::AccessDenied.new(
        "Accès à la fonctionnalité '#{feature}' refusé pour votre profil.",
        action.to_sym,
        feature.classify.constantize
      )
    end
  end

  # Mappe l'action du controller vers une action de feature permission.
  def feature_action_name
    case action_name
    when "index", "show"
      "read"
    when "new", "create"
      "create"
    when "edit", "update"
      "update"
    when "destroy"
      "destroy"
    else
      "read"
    end
  end

  # Helper pour les vues : vérifie si l'utilisateur peut accéder à une fonctionnalité.
  def feature_allowed?(feature, action = "read")
    return true if current_user&.root?

    Admin::FeaturePermission.allowed?(current_user, feature, action, @group)
  end
end
