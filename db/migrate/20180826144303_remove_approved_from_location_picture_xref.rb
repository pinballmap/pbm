class RemoveApprovedFromLocationPictureXref < ActiveRecord::Migration[5.2]
  def change
    remove_column :location_picture_xrefs, :approved
  end
end
