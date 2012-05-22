class LocationPictureXref < ActiveRecord::Base
  belongs_to :location
  belongs_to :user

  has_attached_file :photo,
    :storage => :s3,
    :bucket => ENV['S3_BUCKET_NAME'],
    :path => "location_picture_xref/photo/:id/:photo_file_name",
    :url => "https://s3.amazonaws.com/pbm-images/location_picture_xref/photo/:id/:photo_file_name",
    :styles => {
      :thumb => "36x25>",
      :medium => "300x300>",
    },
    :s3_credentials => {
      :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
      :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
    }

  def rails_admin_default_object_label_method
  end
end
