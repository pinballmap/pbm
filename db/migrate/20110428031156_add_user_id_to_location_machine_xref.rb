class AddUserIdToLocationMachineXref < ActiveRecord::Migration
  def self.up
    add_column :location_machine_xrefs, :user_id, :integer
  end

  def self.down
    remove_column :location_machine_xrefs, :user_id
  end
end
