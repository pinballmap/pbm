class AddMachineScoreXrefsCountToLocationMachineXrefs < ActiveRecord::Migration[4.2]
  def self.up
    add_column :location_machine_xrefs, :machine_score_xrefs_count, :integer
  end

  def self.down
    remove_column :location_machine_xrefs, :machine_score_xrefs_count
  end
end
