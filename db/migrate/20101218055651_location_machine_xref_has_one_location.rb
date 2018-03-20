class LocationMachineXrefHasOneLocation < ActiveRecord::Migration[4.2]
  def self.up
    add_column :location_machine_xrefs, :location_id, :integer
    add_column :location_machine_xrefs, :machine_id, :integer
  end

  def self.down
    remove_column :location_machine_xrefs, :location_id, :integer
    remove_column :location_machine_xrefs, :machine_id, :integer
  end
end
