class AddIsSternArmyToLocations < ActiveRecord::Migration[5.1]
  def change
    add_column :locations, :is_stern_army, :boolean
  end
end
