class AddMachineGroupIdToMachines < ActiveRecord::Migration
  def change
    add_column :machines, :machine_group_id, :integer
  end
end
