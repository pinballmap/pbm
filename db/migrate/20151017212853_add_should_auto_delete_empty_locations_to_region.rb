class AddShouldAutoDeleteEmptyLocationsToRegion < ActiveRecord::Migration[4.2]
  def change
    add_column :regions, :should_auto_delete_empty_locations, :boolean
  end
end
