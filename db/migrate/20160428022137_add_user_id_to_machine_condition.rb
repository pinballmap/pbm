class AddUserIdToMachineCondition < ActiveRecord::Migration
  def change
    add_column :machine_conditions, :user_id, :integer
  end
end
