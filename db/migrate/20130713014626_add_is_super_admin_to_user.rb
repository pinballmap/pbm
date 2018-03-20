class AddIsSuperAdminToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :is_super_admin, :bool
  end
end
