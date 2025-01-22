class LocationPictureXrefsController < InheritedResources::Base
  respond_to :html, :xml, :json, :rss, only: %i[index show]
  has_scope :region
  before_action :authenticate_user!, except: %i[index show]

  def form
    render partial: "location_picture_xrefs/form", locals: { l: Location.find(params[:id]) }
  end

  def create
    @location_picture_xref = LocationPictureXref.new(location_picture_xref_params)

    respond_to do |format|
      format.js if @location_picture_xref.save
    end

    @location_picture_xref.user = current_user
    @location_picture_xref.create_user_submission
  end

  def destroy
    lpx = LocationPictureXref.find_by_id(params[:id])

    lpx.destroy

    render nothing: true
  end

  private

  def location_picture_xref_params
    params.require(:location_picture_xref).permit(:location_id, :description, :user_id, :photo_file_name, :photo_content_type, :photo_file_size, :photo)
  end
end
