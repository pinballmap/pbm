class ChangeRegionLatLonToNumerics < ActiveRecord::Migration[4.2]
  def change
    change_column :regions, :lat, :decimal, :precision => 18, :scale => 12
    change_column :regions, :lon, :decimal, :precision => 18, :scale => 12
  end
end
