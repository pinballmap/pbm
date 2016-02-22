class LocationsController < InheritedResources::Base
  respond_to :xml, :json, :html, :js, :rss
  has_scope :by_location_name, :by_location_id, :by_ipdb_id, :by_machine_id, :by_machine_name, :by_city_id, :by_machine_group_id, :by_zone_id, :by_operator_id, :by_type_id, :by_at_least_n_machines_city, :by_at_least_n_machines_zone, :by_at_least_n_machines_type, :region

  def autocomplete
    render json: @region.locations.select { |l| l.name =~ /#{Regexp.escape params[:term] || ''}/i }.sort_by(&:name).map { |l| { label: l.name, value: l.name, id: l.id } }
  end

  def index
    @locations = apply_scopes(Location).order('locations.name').includes(:location_machine_xrefs, :machines, :location_picture_xrefs)
    @location_data = locations_javascript_data(@locations)

    respond_with(@locations) do |format|
      format.html { render partial: 'locations/locations', layout: false }
    end
  end

  def locations_for_machine
    @locations = @region.location_machine_xrefs.reject { |lmx| lmx.machine_id.to_s != params[:id] }.map { |lmx| lmx.location }.sort_by(&:name)
  end

  def render_machines
    render partial: 'locations/render_machines', locals: { location_machine_xrefs: Location.find(params[:id]).location_machine_xrefs }
  end

  def render_machine_names_for_infowindow
    render text: Location.find(params[:id]).machine_names.join('<br />')
  end

  def render_scores
    render partial: 'locations/render_scores', locals: { lmx: LocationMachineXref.find(params[:id]) }
  end

  def render_desc
    render partial: 'locations/render_desc', locals: { l: Location.find(params[:id]) }
  end

  def render_update_metadata
    render partial: 'locations/render_update_metadata', locals: { l: Location.find(params[:id]) }
  end

  def render_last_updated
    render partial: 'locations/render_last_updated', locals: { l: Location.find(params[:id]) }
  end

  def render_add_machine
    render partial: 'locations/render_add_machine', locals: { l: Location.find(params[:id]) }
  end

  def update_metadata
    validation_error = []
    id = params[:id]

    l = Location.find(id)

    l.operator_id = params["new_operator_#{id}".to_sym]
    l.location_type_id = params["new_location_type_#{id}".to_sym]
    l.save(validate: false)

    old_phone = l.phone
    l.phone = params["new_phone_#{id}".to_sym]
    unless l.valid?
      l.phone = old_phone
      validation_error.push(l.errors.full_messages.join(''))
      l.errors.clear
    end

    old_website = l.website
    l.website = params["new_website_#{id}".to_sym]
    unless l.valid?
      l.website = old_website
      validation_error.push(l.errors.full_messages.join(''))
      l.errors.clear
    end

    if ENV['RAKISMET_KEY']
      if l.spam?
        nil
      else
        l.save(validate: false)
      end
      l
    else
      l.save(validate: false)
      l
    end

    if validation_error.length > 0
      render json: { error: validation_error.uniq.join('<br />') }
    else
      render nothing: true
    end
  end

  def update_desc
    id = params[:id]

    l = Location.find(id)
    l.description = params["new_desc_#{id}".to_sym]

    l.description = l.description.slice(0, 254) unless l.description.nil?

    if l.description !~ %r{http:\/\/}
      if ENV['RAKISMET_KEY']
        if l.spam?
          nil
        else
          l.date_last_updated = Date.today
          l.save(validate: false)
        end
        l
      else
        l.date_last_updated = Date.today
        l.save(validate: false)
        l
      end
    else
      l
    end

    render nothing: true
  end

  def mobile
    region = params[:region] || 'portland'
    format = params[:format] || 'xml'

    if params[:init]
      init_mobile(region, format, params)
    elsif (location_id = params[:get_location])
      redirect_to "/#{region}/locations/#{location_id}.#{format}"
    elsif (machine_id = params[:get_machine])
      redirect_to "/#{region}/locations/#{machine_id}/locations_for_machine.#{format}"
    elsif params[:condition]
      update_condition_mobile(region, format, params)
    elsif params[:modify_location]
      modify_location_mobile(region, format, params)
    end
  end

  def modify_location_mobile(region, format, params)
    location_id = params[:modify_location]

    # unfortunately, the mobile devices are sending us a parameter called 'action'...
    # until I figure out a way to handle this, I assume if a machine doesn't exist at
    # a location, create it..if it does, destroy it
    machine_name = params[:machine_name]

    machine_name.strip! unless machine_name.nil?

    machine = params[:machine_no] ? Machine.find(params[:machine_no]) : Machine.where(['lower(name) = ?', machine_name.downcase]).first

    if machine.nil?
      machine = Machine.create(name: machine_name)

      send_new_machine_notification(machine, Location.find(params[:modify_location]))
    end

    if (lmx = LocationMachineXref.find_by_location_id_and_machine_id(location_id, machine.id))
      id = lmx.id
      lmx.destroy(remote_ip: request.remote_ip, request_host: request.host, user_agent: request.user_agent)

      redirect_to "/#{region}/location_machine_xrefs/#{id}/remove_confirmation.#{format}"
    else
      lmx = LocationMachineXref.create(location_id: location_id, machine_id: machine.id)
      redirect_to "/#{region}/location_machine_xrefs/#{lmx.id}/create_confirmation.#{format}"
    end
  end

  def update_condition_mobile(region, format, params)
    lmx = LocationMachineXref.find_by_location_id_and_machine_id(params[:location_no], params[:machine_no])
    lmx.update_condition(params[:condition], remote_ip: request.remote_ip, request_host: request.host, user_agent: request.user_agent)

    redirect_to "/#{region}/location_machine_xrefs/#{lmx.id}/condition_update_confirmation.#{format}"
  end

  def init_mobile(region, format, params)
    case params[:init].to_i
    when 1 then
      redirect_to "/#{region}/locations.#{format}"
    when 2 then
      redirect_to "/#{region}/regions.#{format}"
    when 3 then
      redirect_to "/#{region}/events.#{format}"
    when 4 then
      redirect_to "/#{region}/machines.#{format}"
    when 5 then
      redirect_to "/#{region}/all_region_data.json"
    end
  end

  def locations_javascript_data(locations)
    ids = []
    lats = []
    lons = []
    contents = []

    locations.each do |l|
      ids      << l.id
      lats     << l.lat
      lons     << l.lon
      contents << l.content_for_infowindow
    end

    [ids, lats, lons, contents]
  end

  def newest_machine_name
    render text: Location.find(params[:id]).newest_machine_xref.machine.name
  end

  def confirm
    l = Location.find(params[:id])
    l.date_last_updated = Date.today
    l.save(validate: false)
    l
  end
end
