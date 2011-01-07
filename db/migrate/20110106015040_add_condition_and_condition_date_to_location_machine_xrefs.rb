class AddConditionAndConditionDateToLocationMachineXrefs < ActiveRecord::Migration
  def self.up
    add_column :location_machine_xrefs, :condition, :string
    add_column :location_machine_xrefs, :condition_date, :date
  end

  def self.down
    remove_column :location_machine_xrefs, :condition, :string
    remove_column :location_machine_xrefs, :condition_date, :date
  end
end
