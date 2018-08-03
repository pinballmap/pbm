class AddUserIdIndexToMachineCondition < ActiveRecord::Migration[5.2]
  def change
    add_index :machine_conditions, :user_id
  end
end
