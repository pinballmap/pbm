class ZonesController < InheritedResources::Base
  respond_to :html, :xml, :json, :rss, only: %i[index show]
  has_scope :region

  def create
    @zone = Zone.new(zone_params)
    if @zone.save
      redirect_to @zone, notice: 'Zone was successfully created.'
    else
      render action: 'new'
    end
  end

  private

  def zone_params
    params.require(:zone).permit(:name, :region_id, :short_name, :is_primary)
  end
end
