class AddIpToLocationMachineXref < ActiveRecord::Migration
  def self.up
    add_column :location_machine_xrefs, :ip, :string
  end

  def self.down
    remove_column :location_machine_xrefs, :ip
  end
end
