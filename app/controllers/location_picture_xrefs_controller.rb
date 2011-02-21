class LocationPictureXrefsController < InheritedResources::Base
  def create
    @location_picture_xref = LocationPictureXref.create(params[:location_picture_xref])

    respond_to do |format|
      if @location_picture_xref.save
        format.js
      end
    end
  end
end
