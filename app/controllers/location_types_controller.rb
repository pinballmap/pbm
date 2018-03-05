class LocationTypesController < InheritedResources::Base
  respond_to :html, :xml, :json, :rss, only: %i[index show]
  has_scope :region

  def create
    @location_type = LocationType.new(location_type_params)
    if @location_type.save
      redirect_to @location_type, notice: 'LocationType was successfully created.'
    else
      render action: 'new'
    end
  end

  private

  def location_type_params
    params.require(:location_type).permit(:name)
  end
end
