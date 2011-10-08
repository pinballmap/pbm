class LocationPictureXrefsController < InheritedResources::Base
  def create
    @location_picture_xref = LocationPictureXref.create(params[:location_picture_xref])

    respond_to do |format|
      if @location_picture_xref.save
        format.js
      end
    end

    Pony.mail(
      :to => @location_picture_xref.location.region.users.collect {|u| u.email},
      :from => 'admin@pinballmap.com',
      :subject => 'PBM - Someone wants you to approve a picture',
      :body => "This is photo ID: #{@location_picture_xref.id}. It's at location: #{@location_picture_xref.location.name}.\nTo approve it, please visit here http://pinballmap.com/admin/location_picture_xrefs\nOnce there, click 'edit' and then tick the 'approve' button.",
      :attachments => {@location_picture_xref.photo.to_s => File.read(RAILS_ROOT + '/public/' + @location_picture_xref.photo.to_s)}
    )
  end
end
