class AddExternalLocationNameToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :external_location_name, :string
  end
end
