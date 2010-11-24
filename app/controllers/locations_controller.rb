class LocationsController < InheritedResources::Base
#  has_scope :by_name

  def index
    @locations = Location.search(params[:by_name]).paginate(:per_page => 5, :page => params[:page])

    render
  end
end
