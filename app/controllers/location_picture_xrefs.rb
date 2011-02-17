class LocationPictureXrefsController < InheritedResources::Base
  def create
    @location_picture_xref = LocationPictureXref.create(params[:location_picture_xref])
  end
end
