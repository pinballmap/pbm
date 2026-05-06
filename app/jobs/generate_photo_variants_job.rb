class GeneratePhotoVariantsJob < ApplicationJob
  queue_as :default

  def perform(lpx_id)
    lpx = LocationPictureXref.includes(photo_attachment: :blob).find(lpx_id)
    return unless lpx.photo.attached?

    lpx.photo.variant(resize_to_limit: [ 240, 240 ]).processed
    lpx.photo.variant(resize_to_limit: [ 1200, 1200 ]).processed
  rescue ActiveRecord::RecordNotFound
    # record was deleted before the job ran
  end
end
