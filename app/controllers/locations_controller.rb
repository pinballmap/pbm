class LocationsController < InheritedResources::Base
  has_scope :by_location_name, :by_location_id, :by_machine_id

  def autocomplete
#    render :json => Location.search(params[:by_name]).map { |l| l.name }
  end

  def index
    @locations = apply_scopes(Location).all

    render
  end
end
