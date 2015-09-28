class AddDateLastUpdatedToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :date_last_updated, :date
  end
end
