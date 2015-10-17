class AddShouldAutoDeleteEmptyLocationsToRegion < ActiveRecord::Migration
  def change
    add_column :regions, :should_auto_delete_empty_locations, :boolean
  end
end
