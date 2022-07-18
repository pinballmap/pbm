class LocationPictureXrefsController < InheritedResources::Base
  respond_to :html, :xml, :json, :rss, only: %i[index show]
  has_scope :region

  def create
    @location_picture_xref = LocationPictureXref.new(location_picture_xref_params)

    respond_to do |format|
      format.js if @location_picture_xref.save
    end

    Pony.mail(
      to: @location_picture_xref.location.region_id && @location_picture_xref.location.region.users.map(&:email).present? ? @location_picture_xref.location.region.users.map(&:email) : User.where("is_super_admin = 't'").map(&:email),
      from: 'admin@pinballmap.com',
      subject: 'PBM - Someone added a picture',
      body: "This is photo ID: #{@location_picture_xref.id}. It's at location: #{@location_picture_xref.location.name}. Region: #{@location_picture_xref.location.region_id ? @location_picture_xref.location.region.full_name : 'REGIONLESS'}.\n\n\nYou can view the picture here #{@location_picture_xref.photo.url(:large)}\n\n\nNo need to approve it, it's already live."
    )
  end

  private

  def location_picture_xref_params
    params.require(:location_picture_xref).permit(:location_id, :description, :user_id, :photo_file_name, :photo_content_type, :photo_file_size, :photo)
  end
end
