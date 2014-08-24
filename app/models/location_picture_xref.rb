class LocationPictureXref < ActiveRecord::Base
  belongs_to :location
  belongs_to :user

  has_attached_file :photo,
    :storage => :s3,
    :bucket => 'pbm-images',
    :path => "location_picture_xref/photo/:id/:style/:filename",
    :url => "https://s3.amazonaws.com/pbm-images/location_picture_xref/photo/:id/medium/:filename",
    :styles => {
      :thumb => "36x25>",
      :medium => "300x300>",
    },
    :s3_credentials => {
      :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
      :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
    }

  attr_accessible :location_id, :description, :approved, :user_id, :photo_file_name, :photo_content_type, :photo_file_size, :photo

  do_not_validate_attachment_file_type :photo

  def rails_admin_default_object_label_method
  end
end
