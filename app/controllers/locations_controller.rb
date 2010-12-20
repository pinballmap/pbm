class LocationsController < InheritedResources::Base
  has_scope :by_name

  def autocomplete
p params[:by_name]
#    render :json => Location.search(params[:by_name]).map { |l| l.name }
  end

  def index
    @locations = Location.search(params[:by_name], params[:by_id]).paginate(:per_page => 5, :page => params[:page])

    render
  end
end
