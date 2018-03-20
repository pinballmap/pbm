class AddUserIdToLocationPictureXref < ActiveRecord::Migration[4.2]
  def self.up
    add_column :location_picture_xrefs, :user_id, :integer
  end

  def self.down
    remove_column :location_picture_xrefs, :user_id
  end
end
