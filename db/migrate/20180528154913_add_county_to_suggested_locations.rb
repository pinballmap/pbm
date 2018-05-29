class AddCountyToSuggestedLocations < ActiveRecord::Migration[5.1]
  def change
    add_column :suggested_locations, :country, :text
  end
end
