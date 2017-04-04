class AddIsMachineAdminToUsers < ActiveRecord::Migration
  def change
    add_column :users, :is_machine_admin, :boolean
  end
end
