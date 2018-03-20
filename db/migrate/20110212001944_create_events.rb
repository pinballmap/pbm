class CreateEvents < ActiveRecord::Migration[4.2]
  def self.up
    create_table :events do |t|
      t.integer :region_id
      t.string :name
      t.text :long_desc
      t.string :link
      t.integer :category_no
      t.date :start_date
      t.date :end_date
      t.integer :location_id

      t.timestamps
    end
  end

  def self.down
    drop_table :events
  end
end
