class SetPrecisionAndScaleToLocationLatLon < ActiveRecord::Migration[6.1]
  def up
    change_column :locations, :lat, :decimal, :scale => 12, :precision => 18
    change_column :locations, :lon, :decimal, :scale => 12, :precision => 18
  end

  def down
    change_column :locations, :lat, :float
    change_column :locations, :lon, :float
  end
end

