class SuggestedLocationsController < InheritedResources::Base
  respond_to :xml, :json, :html, :js, :rss
  before_action :authenticate_user!

  def create
    @suggested_location = SuggestedLocation.new(suggested_location_params)
    if @suggested_location.save
      redirect_to @suggested_location, notice: 'SuggestedLocation was successfully created.'
    else
      render action: 'new'
    end
  end

  def convert_to_location
    sl = SuggestedLocation.find(params[:id])
    sl.convert_to_location(params[:user_email])

    if sl.errors.any?
      redirect_to "/admin/suggested_location/#{sl.id}", flash: { error: sl.errors.full_messages.join(', ') }
    else
      redirect_to rails_admin_path
    end
  end

  private

  def suggested_location_params
    params.require(:suggested_location).permit(:name, :street, :city, :state, :zip, :country, :phone, :lat, :lon, :website, :region_id, :location_type_id, :comments, :zone_id, :zone, :operator_id, :machines, :region, :operator, :location_type, :user_inputted_address)
  end
end
