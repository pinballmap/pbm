class AddMachineGroupIdToMachines < ActiveRecord::Migration[4.2]
  def change
    add_column :machines, :machine_group_id, :integer
  end
end
