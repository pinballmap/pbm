class LocationPictureXref < ActiveRecord::Base
  attr_accessible :location_picture_xref_id, :photo, :location_id
  belongs_to :location
  belongs_to :user
  mount_uploader :photo, PhotoUploader
end
