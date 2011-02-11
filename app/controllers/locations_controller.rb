class LocationsController < InheritedResources::Base
  respond_to :xml, :json, :html, :js
  has_scope :by_location_name, :by_location_id, :by_machine_id, :by_machine_name, :by_city, :by_zone_id

  def autocomplete
    render :json => Location.find(:all, :conditions => ['name like ?', '%' + params[:term] + '%']).map { |l| l.name }
  end

  def update_machine_condition
    lmx_id = params[:location_machine_xref_id]

    lmx = LocationMachineXref.find(lmx_id)
    lmx.condition = params["new_machine_condition_#{lmx_id}".to_sym]
    lmx.condition_date = Time.now
    lmx.save
  end

  def add_high_score
    msx = MachineScoreXref.create(:location_machine_xref_id => params[:location_machine_xref_id])
    msx.score = params[:score]
    msx.initials = params[:initials]
    msx.rank = params[:rank]

    msx.save
    msx.sanitize_scores
  end

  def index
    respond_with(@locations = apply_scopes(Location).where('region_id = ?', @region.id))
  end

  def render_machines
    render :partial => 'locations/render_machines', :locals => {:location => Location.find(params[:id])}
  end

  def render_scores
    render :partial => 'locations/render_scores', :locals => {:lmx => LocationMachineXref.find(params[:id])}
  end

  def unknown_route
    if (params[:page] == 'iphone.html')
      if (params[:init])
        case params[:init].to_i
        when 1 then
          redirect_to "/#{params[:region]}/locations.xml"
        when 2 then
          redirect_to "/#{params[:region]}/regions.xml"
        when 4 then
#          redirect_to "/#{params[:region]}/location_machine_xrefs.xml"
        end
      elsif (location_id = params[:get_location])
        redirect_to "/#{params[:region]}/locations/#{location_id}.xml"
      elsif (location_id = params[:get_machine])
      elsif (location_id = params[:error])
      elsif (location_id = params[:condition])
      elsif (location_id = params[:modify_location])
        if (params[:add_machine])
        elsif (params[:remove_machine])
        end
      end
    end
  end
end
