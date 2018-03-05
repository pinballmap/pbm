class AddDateLastUpdatedToLocations < ActiveRecord::Migration[4.2]
  def change
    add_column :locations, :date_last_updated, :date
  end
end
