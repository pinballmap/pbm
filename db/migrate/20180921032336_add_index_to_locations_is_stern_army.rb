class AddIndexToLocationsIsSternArmy < ActiveRecord::Migration[5.2]
  def change
    add_index :locations, :is_stern_army
  end
end
