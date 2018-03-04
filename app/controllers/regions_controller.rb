class RegionsController < InheritedResources::Base
  respond_to :xml, :json

  def create
    @region = Region.new(region_params)
    if @region.save
      redirect_to @region, notice: 'Region was successfully created.'
    else
      render action: 'new'
    end
  end

  def index
    respond_with(@regions = Region.all, methods: %i[subdir emailContact])
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

  private
  def region_params
    params.require(:region).permit(:name, :full_name, :motd, :lat, :lon, :n_search_no, :default_search_type, :should_email_machine_removal, :should_auto_delete_empty_locations, :send_digest_comment_emails, :send_digest_removal_emails)
  end
end
