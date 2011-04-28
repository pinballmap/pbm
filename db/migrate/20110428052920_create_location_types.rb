class CreateLocationTypes < ActiveRecord::Migration
  def self.up
    create_table :location_types do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :location_types
  end
end
