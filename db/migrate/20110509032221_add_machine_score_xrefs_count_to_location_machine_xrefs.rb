class AddMachineScoreXrefsCountToLocationMachineXrefs < ActiveRecord::Migration
  def self.up
    add_column :location_machine_xrefs, :machine_score_xrefs_count, :integer, :default => 0

    LocationMachineXref.reset_column_information
    LocationMachineXref.all.each do |lmx|
      lmx.update_attribute :machine_score_xrefs_count, lmx.machine_score_xrefs.length
    end

    LocationMachineXref.reset_column_information
    LocationMachineXref.find_each do |lmx|
      LocationMachineXref.reset_counters lmx.id, :location_machine_xrefs
    end
  end

  def self.down
    remove_column :location_machine_xrefs, :machine_score_xrefs_count
  end
end
