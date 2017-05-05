class SuggestedLocationsController < InheritedResources::Base
  respond_to :xml, :json, :html, :js, :rss
  before_action :authenticate_user!

  def convert_to_location
    sl = SuggestedLocation.find(params[:id])
    sl.convert_to_location

    redirect_to sl.errors.any? ? "/admin/suggested_location/#{sl.id}" : rails_admin_path
  end
end
