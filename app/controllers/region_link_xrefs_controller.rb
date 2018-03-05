class RegionLinkXrefsController < InheritedResources::Base
  respond_to :html, :xml, :json, :rss, only: %i[index show]
  has_scope :region

  def create
    @region_link_xref = RegionLinkXref.new(region_link_xref_params)
    if @region_link_xref.save
      redirect_to @region_link_xref, notice: 'RegionLinkXref was successfully created.'
    else
      render action: 'new'
    end
  end

  private

  def region_link_xref_params
    params.require(:region_link_xref).permit(:name, :url, :description, :category, :region_id, :sort_order)
  end
end
