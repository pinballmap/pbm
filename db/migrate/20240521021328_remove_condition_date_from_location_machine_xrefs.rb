class RemoveConditionDateFromLocationMachineXrefs < ActiveRecord::Migration[7.0]
  def change
    remove_column :location_machine_xrefs, :condition_date, :date
  end
end
