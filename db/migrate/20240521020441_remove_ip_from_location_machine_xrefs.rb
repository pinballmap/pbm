class RemoveIpFromLocationMachineXrefs < ActiveRecord::Migration[7.0]
  def change
    remove_column :location_machine_xrefs, :ip, :string
  end
end
