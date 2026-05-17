# frozen_string_literal: true

class CreateAdminFeaturePermissions < ActiveRecord::Migration[6.1]
  def change
    create_table :admin_feature_permissions do |t|
      t.string :feature,    null: false  # "finance", "maas", "progression"
      t.string :action,     null: false  # "read", "create", "update", "destroy", "manage"
      t.string :role_type,  null: false  # "Group::Bund::Kassier"
      t.string :group_type, null: true   # "Group::Bund" (null = tous les groupes)
      t.boolean :allowed,   null: false, default: true

      t.timestamps
    end

    add_index :admin_feature_permissions,
              [:feature, :action, :role_type, :group_type],
              unique: true,
              name: "idx_admin_feature_perm_unique"
    add_index :admin_feature_permissions, :feature
    add_index :admin_feature_permissions, :role_type
  end
end
