class BannedIpsController < InheritedResources::Base
  respond_to :html, :xml, :json, :rss, only: %i[index show]
  has_scope :region

  def create
    @banned_ip = BannedIps.new(banned_ip_params)
    if @banned_ip.save
      redirect_to @banned_ip, notice: 'BannedIps was successfully created.'
    else
      render action: 'new'
    end
  end

  private
  def banned_ip_params
    params.require(:banned_ip).permit(:ip_address)
  end
end
