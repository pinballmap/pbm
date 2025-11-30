class AddDeletedAtToLocationMachineXrefs < ActiveRecord::Migration[8.0]
  def change
    add_column :location_machine_xrefs, :deleted_at, :datetime
  end
end
