class RemoveMachineScoreXrefsCountFromLocationMachineXrefs < ActiveRecord::Migration[8.0]
  def self.down
    remove_column :location_machine_xrefs, :machine_score_xrefs_count, :integer
  end

  def self.up
    remove_column :location_machine_xrefs, :machine_score_xrefs_count, :integer
  end
end
