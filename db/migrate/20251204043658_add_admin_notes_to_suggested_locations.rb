class AddAdminNotesToSuggestedLocations < ActiveRecord::Migration[8.0]
  def self.up
    add_column :suggested_locations, :admin_notes, :string
  end

  def self.down
    remove_column :suggested_locations, :admin_notes
  end
end
