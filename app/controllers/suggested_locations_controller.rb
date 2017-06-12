class SuggestedLocationsController < InheritedResources::Base
  respond_to :xml, :json, :html, :js, :rss
  before_action :authenticate_user!

  def convert_to_location
    sl = SuggestedLocation.find(params[:id])
    sl.convert_to_location(params[:user_email])

    if sl.errors.any?
      redirect_to "/admin/suggested_location/#{sl.id}", flash: { error: sl.errors.full_messages.join(', ') }
    else
      redirect_to rails_admin_path
    end
  end
end
