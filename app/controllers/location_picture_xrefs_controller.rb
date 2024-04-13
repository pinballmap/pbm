class LocationPictureXrefsController < InheritedResources::Base
  respond_to :html, :xml, :json, :rss, only: %i[index show]
  has_scope :region
  before_action :authenticate_user!, except: %i[index show]

  def create
    @location_picture_xref = LocationPictureXref.new(location_picture_xref_params)

    respond_to do |format|
      format.js if @location_picture_xref.save
    end

    to_users = @location_picture_xref.location.region_id && @location_picture_xref.location.region.users.map(&:email).present? ? @location_picture_xref.location.region.users.map(&:email) : User.where("is_super_admin = 't'").map(&:email)

    AdminMailer.with(to_users: to_users, subject: 'Pinball Map - Picture added', photo_id: @location_picture_xref.id, location_name: @location_picture_xref.location.name, region_name: @location_picture_xref.location.region_id ? @location_picture_xref.location.region.full_name : 'REGIONLESS', photo_url: @location_picture_xref.photo.url(:large)).picture_added.deliver_now
  end

  def destroy
    lpx = LocationPictureXref.find_by_id(params[:id])

    AdminMailer.with(photo_id: lpx.id, location_name: lpx.location.name).picture_removed.deliver_now

    lpx.destroy

    render nothing: true
  end

  private

  def location_picture_xref_params
    params.require(:location_picture_xref).permit(:location_id, :description, :user_id, :photo_file_name, :photo_content_type, :photo_file_size, :photo)
  end
end
