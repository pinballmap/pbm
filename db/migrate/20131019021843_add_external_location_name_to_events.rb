class AddExternalLocationNameToEvents < ActiveRecord::Migration
  def change
    add_column :events, :external_location_name, :string
  end
end
