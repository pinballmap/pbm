class RemoveOperatorIdFromLocationMachineXrefs < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :location_machine_xrefs, :operator_id
  end

  def self.down
    add_column :location_machine_xrefs, :operator_id, :integer
  end
end
