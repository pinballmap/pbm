class AddApprovedToLocationPictureXref < ActiveRecord::Migration[4.2]
  def self.up
    add_column :location_picture_xrefs, :approved, :boolean
  end

  def self.down
    remove_column :location_picture_xrefs, :approved
  end
end
