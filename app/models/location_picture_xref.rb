class LocationPictureXref < ApplicationRecord
  belongs_to :location, optional: true
  belongs_to :user, optional: true

  has_one_attached :photo

  validates :photo, content_type: { in: %w[image/jpeg image/png image/webp image/heic image/heif], message: "must be a JPEG, PNG, WebP, or HEIC" },
                    size: { less_than: 30.megabytes, message: "must be under 30MB" }

  after_create_commit :enqueue_variant_generation

  def rails_admin_default_object_label_method; end

  def create_remove_user_submission(removing_user)
    user_info = removing_user ? removing_user.username : "UNKNOWN USER"
    submission = "#{user_info} removed a picture of #{location.name} in #{location.city}"

    UserSubmission.create(
      user_name:       user_info,
      location_name:   location.name,
      city_name:       location.city,
      lat:             location.lat,
      lon:             location.lon,
      region_id:       location.region_id,
      location:        location,
      submission_type: UserSubmission::REMOVE_PICTURE_TYPE,
      submission:      submission,
      user:            removing_user
    )
  end

  def create_user_submission
    user_info = user ? user.username : "UNKNOWN USER"
    submission = "#{user_info} added a picture of #{location.name} in #{location.city}"

    UserSubmission.create(user_name: user.username, location_name: location.name, city_name: location.city, lat: location.lat, lon: location.lon, region_id: location.region_id, location: location, submission_type: UserSubmission::NEW_PICTURE_TYPE, submission: submission, user: user)
    Rails.logger.info "USER SUBMISSION USER ID #{user&.id} #{submission}"
    location.users_count = UserSubmission.where(location_id: location.id).count("DISTINCT user_id")
    location.save(validate: false)
  end

  private

  def enqueue_variant_generation
    GeneratePhotoVariantsJob.perform_later(id) if photo.attached?
  end
end
