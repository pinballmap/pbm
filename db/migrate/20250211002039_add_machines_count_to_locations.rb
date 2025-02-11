class AddMachinesCountToLocations < ActiveRecord::Migration[7.2]
  def change
    add_column :locations, :machine_count, :integer, default: 0, null: false
  end
end
