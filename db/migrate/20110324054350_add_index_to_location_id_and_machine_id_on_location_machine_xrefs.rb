class AddIndexToLocationIdAndMachineIdOnLocationMachineXrefs < ActiveRecord::Migration
  def self.up
    add_index :location_machine_xrefs, :location_id
    add_index :location_machine_xrefs, :machine_id
  end

  def self.down
    remove_index :location_machine_xrefs, :location_id
    remove_index :location_machine_xrefs, :machine_id
  end
end
