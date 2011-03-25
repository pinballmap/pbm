class AddLocationMachineXrefIndexOnMachineScoreXrefs < ActiveRecord::Migration
  def self.up
    add_index :machine_score_xrefs, :location_machine_xref_id
  end

  def self.down
    remove_index :machine_score_xrefs, :location_machine_xref_id
  end
end
