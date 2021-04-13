class AddIconToLocationType < ActiveRecord::Migration[5.2]
  def change
    add_column :location_types, :icon, :string
    add_column :location_types, :library, :string
  end
end
