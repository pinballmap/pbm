class AddCountyToLocations < ActiveRecord::Migration[5.1]
  def change
    add_column :locations, :country, :text
  end
end
