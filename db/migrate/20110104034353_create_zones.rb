class CreateZones < ActiveRecord::Migration
  def self.up
    create_table :zones do |t|
      t.string :name
      t.integer :region_id

      t.timestamps
    end
  end

  def self.down
    drop_table :zones
  end
end
