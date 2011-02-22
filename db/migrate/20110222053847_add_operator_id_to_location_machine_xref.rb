class AddOperatorIdToLocationMachineXref < ActiveRecord::Migration
  def self.up
    add_column :location_machine_xrefs, :operator_id, :integer
  end

  def self.down
    remove_column :location_machine_xrefs, :operator_id
  end
end
