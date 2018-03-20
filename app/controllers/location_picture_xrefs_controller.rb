class LocationPictureXrefsController < InheritedResources::Base
  respond_to :html, :xml, :json, :rss, only: %i[index show]
  has_scope :region

  def create
    @location_picture_xref = LocationPictureXref.new(location_picture_xref_params)
    if @location_picture_xref.save
      redirect_to @location_picture_xref, notice: 'LocationPictureXref was successfully created.'
    else
      render action: 'new'
    end
  end

  private

  def location_picture_xref_params
    params.require(:location_picture_xref).permit(:location_id, :description, :approved, :user_id, :photo_file_name, :photo_content_type, :photo_file_size, :photo)
  end
end
