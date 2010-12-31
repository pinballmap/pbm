class LocationsController < InheritedResources::Base
  has_scope :by_location_name, :by_location_id, :by_machine_id, :by_machine_name

  def autocomplete
    render :json => Location.find(:all, :conditions => ['name like ?', '%' + params[:term] + '%']).map { |l| l.name }
  end

  def index
    @locations = apply_scopes(Location).all

    render
  end
end
