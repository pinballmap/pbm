
class LocationsController < InheritedResources::Base
  respond_to :xml, :json, :html, :js, :rss
  has_scope :by_location_name, :by_location_id, :by_machine_id, :by_machine_name, :by_city_id, :by_zone_id, :by_operator_id, :by_type_id, :by_at_least_n_machines_city, :by_at_least_n_machines_zone, :by_at_least_n_machines_type, :region

  def autocomplete
    term = params[:term] || ''

    render :json => @region.locations.map{|l| l.name}.grep(/#{params[:term]}/i).sort
  end

  def index
    @locations = apply_scopes(Location).order("locations.name").includes(:location_machine_xrefs, :machines, :location_picture_xrefs)
    @location_data = locations_javascript_data(@locations)

    respond_with(@locations) do |format|
      format.html { render :partial => "locations/locations", :layout => false }
    end
  end

  def locations_for_machine
    @locations = @region.location_machine_xrefs.reject{|lmx| lmx.machine_id.to_s != params[:id]}.map{|lmx| lmx.location}.sort_by(&:name)
  end

  def render_machines
    render :partial => 'locations/render_machines', :locals => {:location_machine_xrefs => Location.find(params[:id]).location_machine_xrefs}
  end

  def render_scores
    render :partial => 'locations/render_scores', :locals => {:lmx => LocationMachineXref.find(params[:id])}
  end

  def render_desc
    render :partial => 'locations/render_desc', :locals => {:l => Location.find(params[:id])}
  end

  def render_add_machine
    render :partial => 'locations/render_add_machine', :locals => {:l => Location.find(params[:id])}
  end

  def update_desc
    id = params[:id]

    l = Location.find(id)
    l.description = params["new_desc_#{id}".to_sym]

    if (ENV['RAKISMET_KEY'])
      l.spam? ? nil : l.save
    else
      l.save
    end

    render :nothing => true
  end

  def mobile
    region = params[:region] || 'portland'

    if (params[:init])
      case params[:init].to_i
      when 1 then
        redirect_to "/#{region}/locations.xml"
      when 2 then
        redirect_to "/#{region}/regions.xml"
      when 3 then
        redirect_to "/#{region}/events.xml"
      when 4 then
        redirect_to "/#{region}/machines.xml"
      when 5 then
        redirect_to "/#{region}/all_region_data.json"
      end
    elsif (location_id = params[:get_location])
      redirect_to "/#{region}/locations/#{location_id}.xml"
    elsif (machine_id = params[:get_machine])
      redirect_to "/#{region}/locations/#{machine_id}/locations_for_machine.xml"
    elsif (location_id = params[:error])
    elsif (condition = params[:condition])
      lmx = LocationMachineXref.find_by_location_id_and_machine_id(params[:location_no], params[:machine_no])
      lmx.update_condition(condition)

      redirect_to "/#{region}/location_machine_xrefs/#{lmx.id}/condition_update_confirmation.xml"
    elsif (location_id = params[:modify_location])
      # unfortunately, the mobile devices are sending us a parameter called 'action'...until I figure out a way to handle this,
      # I assume if a machine doesn't exist at a location, create it..if it does, destroy it
      machine = params[:machine_no] ? Machine.find(params[:machine_no]) : Machine.find_by_name(params[:machine_name])

      if (machine.nil?)
        machine = Machine.create(:name => params[:machine_name])

        send_new_machine_notification(machine, Location.find(params[:modify_location]))
      end

      expire_action :controller => 'location_machine_xrefs', :action => :index, :format => :rss

      if (lmx = LocationMachineXref.find_by_location_id_and_machine_id(location_id, machine.id))
        id = lmx.id
        lmx.destroy

        redirect_to "/#{region}/location_machine_xrefs/#{id}/remove_confirmation.xml"
      else
        lmx = LocationMachineXref.create(:location_id => location_id, :machine_id => machine.id)
        redirect_to "/#{region}/location_machine_xrefs/#{lmx.id}/create_confirmation.xml"
      end
    end
  end

  def locations_javascript_data(locations)
    ids = Array.new
    lats = Array.new
    lons = Array.new
    contents = Array.new

    locations.each do |l|
      cloned_location = l.clone
      ids      << cloned_location.id
      lats     << cloned_location.lat
      lons     << cloned_location.lon
      contents << cloned_location.content_for_infowindow

      cloned_location = nil
    end

    [ids, lats, lons, contents]
  end
end
