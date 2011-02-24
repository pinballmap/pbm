class CreateOperators < ActiveRecord::Migration
  def self.up
    create_table :operators do |t|
      t.integer :id
      t.string :name
      t.integer :region_id
      t.string :email
      t.string :website
      t.string :phone

      t.timestamps
    end
  end

  def self.down
    drop_table :operators
  end
end
