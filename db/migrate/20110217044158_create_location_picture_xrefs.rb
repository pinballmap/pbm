class CreateLocationPictureXrefs < ActiveRecord::Migration[4.2]
  def self.up
    create_table :location_picture_xrefs do |t|
      t.integer :location_picture_xref_no
      t.integer :location_id

      t.timestamps
    end
  end

  def self.down
    drop_table :location_picture_xrefs
  end
end
