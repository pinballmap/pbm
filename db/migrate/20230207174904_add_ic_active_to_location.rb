class AddIcActiveToLocation < ActiveRecord::Migration[6.1]
  def change
    add_column :locations, :ic_active, :boolean
  end
end
