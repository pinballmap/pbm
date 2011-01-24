class RegionsController < InheritedResources::Base
  respond_to :xml, :json, :only => [:index, :show]

  def index
    respond_with(@regions = Region.all)
  end

  def show
    respond_with(@region = Region.find(params[:id]))
  end
end
