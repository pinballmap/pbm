class GeneratePhotoVariantsJob < ApplicationJob
  queue_as :default

  def perform(lpx_id)
    lpx = LocationPictureXref.includes(photo_attachment: :blob).find(lpx_id)
    return unless lpx.photo.attached?

    unless lpx.photo.service.exist?(lpx.photo.blob.key)
      Rails.logger.error "Missing S3 file for LocationPictureXref #{lpx_id}, destroying"
      lpx.destroy
      return
    end

    lpx.photo.variant(resize_to_limit: [ 240, 240 ]).processed
    lpx.photo.variant(resize_to_limit: [ 1200, 1200 ]).processed
  rescue ActiveRecord::RecordNotFound
    # record was deleted before the job ran
  rescue Vips::Error => e
    Rails.logger.error "Corrupt image in LocationPictureXref #{lpx_id}, destroying: #{e.message}"
    lpx&.destroy
  end
end
