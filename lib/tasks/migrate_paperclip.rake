namespace :location_picture_xrefs do
  task migrate_to_active_storage: :environment do
    LocationPictureXref.where.not(photo_file_name: nil).find_each do |lpx|
      # This step helps us catch any attachments we might have uploaded that
      # don't have an explicit file extension in the filename
      image_original = lpx.photo_file_name
      # ext = File.extname(image)
      # image_original = CGI.unescape(image.gsub(ext, "_original#{ext}"))

      # this url pattern can be changed to reflect whatever service you use
      lpx_url = "https://s3.amazonaws.com/pbm-images/location_picture_xref/photo/#{lpx.id}/original/#{image_original}"
      lpx.photo.attach(io: OpenURI.open_uri(lpx_url),
                                   filename: lpx.photo_file_name,
                                   content_type: lpx.photo_content_type)
    rescue OpenURI::HTTPError, URI::InvalidURIError => e
      puts "bad image path #{lpx_url}"
    end
  end
end
