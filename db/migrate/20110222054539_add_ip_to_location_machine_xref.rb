class AddIpToLocationMachineXref < ActiveRecord::Migration[4.2]
  def self.up
    add_column :location_machine_xrefs, :ip, :string
  end

  def self.down
    remove_column :location_machine_xrefs, :ip
  end
end
