# frozen_string_literal: true

# Autorisations pour la gestion de la configuration des accès.
# Seuls les utilisateurs avec la permission :admin peuvent gérer les feature permissions.
class Admin::FeaturePermissionAbility < AbilityDsl::Base
  on(Admin::FeaturePermission) do
    permission(:admin).may(:manage).all
    class_side(:index).if_admin
  end
end
