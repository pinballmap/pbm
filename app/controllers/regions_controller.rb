class RegionsController < InheritedResources::Base
  respond_to :xml, :json

  def index
    respond_with(@regions = Region.all, methods: [:subdir, :emailContact])
  end

  def show
    respond_with(@region = Region.find(params[:id]))
  end

  def four_square_export
    @regions = Region.all
  end

  def all_region_data
    @region = Region.find_by_name(params[:region] || 'portland')
  end
end
