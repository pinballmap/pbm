class AddIcEnabledToLocationMachineXrefs < ActiveRecord::Migration[6.1]
  def change
    add_column :location_machine_xrefs, :ic_enabled, :boolean
  end
end
