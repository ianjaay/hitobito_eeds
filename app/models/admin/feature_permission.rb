# frozen_string_literal: true

# Stocke les autorisations configurables par fonctionnalité, action et type de rôle.
# Consultée par le helper feature_allowed? pour décider si un utilisateur a accès
# à une fonctionnalité EEDS.
#
# Si aucune entrée n'existe pour un rôle/feature donné → fallback sur AbilityDsl (permissif).
# Si une entrée existe avec allowed: false → accès refusé même si AbilityDsl l'aurait autorisé.
class Admin::FeaturePermission < ActiveRecord::Base
  self.table_name = "admin_feature_permissions"

  FEATURES = %w[finance maas progression formation camp groupe].freeze
  ACTIONS  = %w[read create update destroy manage].freeze

  # Métadonnées des fonctionnalités pour l'affichage
  FEATURE_META = {
    "finance"     => { label: "Finances",     icon: "fa-coins",          color: "#28a745" },
    "maas"        => { label: "Cotisations",  icon: "fa-file-invoice",   color: "#fd7e14" },
    "progression" => { label: "Progression",  icon: "fa-chart-line",     color: "#6f42c1" },
    "formation"   => { label: "Formation",    icon: "fa-graduation-cap", color: "#e83e8c" },
    "camp"        => { label: "Camps",        icon: "fa-campground",     color: "#20c997" },
    "groupe"      => { label: "Groupe",       icon: "fa-users",          color: "#007bff" }
  }.freeze

  validates :feature, presence: true, inclusion: {in: FEATURES}
  validates :action,  presence: true, inclusion: {in: ACTIONS}
  validates :role_type, presence: true
  validates :role_type, uniqueness: {scope: [:feature, :action, :group_type]}

  scope :for_feature, ->(f) { where(feature: f) }
  scope :for_role, ->(rt) { where(role_type: rt) }
  scope :denied, -> { where(allowed: false) }
  scope :allowed_entries, -> { where(allowed: true) }

  # Vérifie si un utilisateur a accès à une fonctionnalité pour un groupe donné.
  # Retourne true (accès) ou false (refusé).
  # Si aucune config → true (fallback permissif, AbilityDsl décide ensuite).
  def self.allowed?(user, feature, action, group = nil)
    role_types = user.roles.collect { |r| r.class.name }.uniq

    # Chercher une entrée qui REFUSE explicitement
    denied = where(feature: feature, allowed: false)
      .where(role_type: role_types)
      .where(action: [action.to_s, "manage"])

    if group
      denied = denied.where(group_type: [group.class.name, nil])
    end

    !denied.exists?
  end

  # Retourne la matrice complète { role_type => { "feature:action" => allowed } }
  def self.permission_matrix
    all.each_with_object({}) do |perm, matrix|
      matrix[perm.role_type] ||= {}
      key = "#{perm.feature}:#{perm.action}"
      matrix[perm.role_type][key] = perm.allowed
    end
  end
end
