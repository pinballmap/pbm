class AddIsMachineAdminToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :is_machine_admin, :boolean
  end
end
