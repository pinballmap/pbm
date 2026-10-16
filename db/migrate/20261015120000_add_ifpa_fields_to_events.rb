class AddIfpaFieldsToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :address, :string
    add_column :events, :event_type, :string
    add_column :events, :latitude, :decimal, precision: 18, scale: 12
    add_column :events, :longitude, :decimal, precision: 18, scale: 12
  end
end
