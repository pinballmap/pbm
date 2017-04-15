class AddIsSuperAdminToUser < ActiveRecord::Migration
  def change
    add_column :users, :is_super_admin, :bool
  end
end
