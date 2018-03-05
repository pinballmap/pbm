class RemoveLocationPictureXrefNoFromLocationPictureXref < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :location_picture_xrefs, :location_picture_xref_no
  end

  def self.down
    add_column :location_picture_xrefs, :location_picture_xref_no, :integer
  end
end
