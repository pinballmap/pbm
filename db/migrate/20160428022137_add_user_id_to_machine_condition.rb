class AddUserIdToMachineCondition < ActiveRecord::Migration[4.2]
  def change
    add_column :machine_conditions, :user_id, :integer
  end
end
