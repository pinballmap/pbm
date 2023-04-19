class LocationsController < InheritedResources::Base
  respond_to :xml, :json, :html, :js, :rss
  has_scope :by_location_name, :by_location_id, :by_ipdb_id, :by_opdb_id, :by_machine_id, :by_machine_name, :by_city_id, :by_state_id, :by_machine_group_id, :by_zone_id, :by_operator_id, :by_type_id, :by_at_least_n_machines_city, :by_at_least_n_machines_zone, :by_at_least_n_machines_type, :by_center_point_and_ne_boundary, :region, :by_is_stern_army, :user_faved, :manufacturer
  before_action :authenticate_user!, only: %i[update_metadata confirm]

  def create
    @location = Location.new(location_params)
    if @location.save
      redirect_to @location, notice: 'Location was successfully created.'
    else
      render action: 'new'
    end
  end

  def autocomplete
    @searchable_locations = @region ? @region.locations : Location.all
    render json: @searchable_locations.select { |l| l.name.tr('’', "'") =~ /#{Regexp.escape params[:term].tr('’', "'") || ''}/i }.sort_by(&:name).map { |l| { label: "#{l.name} (#{l.city}#{l.state.blank? ? '' : ', '}#{l.state})", value: l.name, id: l.id } }
  end

  def autocomplete_city
    @searchable_cities = Location.select { |l| "#{l.city.tr('’', "'")} #{l.state}" =~ /#{Regexp.escape params[:term].tr('’', "'").tr(',', '') || ''}/i }.sort_by(&:city).map { |l| { label: "#{l.city}#{l.state.blank? ? '' : ', '}#{l.state}", value: "#{l.city}#{l.state.blank? ? '' : ', '}#{l.state}" } }
    render json: @searchable_cities.uniq
  end

  def index
    @region = Region.find_by_name(params[:region])

    params.delete(:by_location_id) if !params[:by_location_name].blank? && !params[:by_location_id].blank?

    @locations = apply_scopes(Location).order('locations.name').includes(:region, :location_type, :location_machine_xrefs, :machines)
    @location_data = LocationsController.locations_javascript_data(@locations)

    respond_with(@locations) do |format|
      format.html { render partial: 'locations/locations', layout: false }
    end
  end

  def locations_for_machine
    @locations = @region.location_machine_xrefs.select { |lmx| lmx.machine_id.to_s == params[:id] }.map(&:location).sort_by(&:name)
  end

  def render_machines
    render partial: 'locations/render_machines', locals: { location_machine_xrefs: LocationMachineXref.where(location_id: params[:id]).includes(:machine, machine_score_xrefs: :user) }
  end

  def render_machines_count
    total_num_machines = Location.find(params[:id]).machine_names.size

    if total_num_machines == 1
      location_machine_count = total_num_machines.to_s + ' machine'
    elsif total_num_machines > 1
      location_machine_count = total_num_machines.to_s + ' machines'
    else
      location_machine_count = 'No machines'
    end

    render plain: location_machine_count
  end

  def render_machine_names_for_infowindow
    infowindow_machines = Location.find(params[:id]).machine_names.take(5).join('<br />')

    total_num_machines = Location.find(params[:id]).machine_names.size

    if total_num_machines > 5
      the_rest = total_num_machines - 5
      and_more_machines = '<br />' + '... and ' + the_rest.to_s + ' more'
    else
      and_more_machines = nil
    end

    new_infowindow_content = infowindow_machines + and_more_machines.to_s

    render plain: new_infowindow_content
  end

  def render_scores
    render partial: 'locations/render_scores', locals: { lmx: LocationMachineXref.find(params[:id]) }
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

  def render_location_detail
    render partial: 'locations/render_location_detail', locals: { l: Location.find(params[:id]) }
  end

  def update_metadata
    l = Location.find(params[:id])

    values, message_type = l.update_metadata(
      current_user.nil? ? nil : current_user,
      phone: params["new_phone_#{l.id}"],
      website: params["new_website_#{l.id}"],
      operator_id: params["new_operator_#{l.id}"],
      location_type_id: params["new_location_type_#{l.id}"],
      description: params["new_desc_#{l.id}"]
    )

    if message_type == 'errors'
      render json: { error: values.uniq.join('<br />') }
    else
      render nothing: true
    end
  end

  def self.locations_javascript_data(locations)
    ids = []
    lats = []
    lons = []
    contents = []
    num_machines = []

    locations.each do |l|
      ids      << l.id
      lats     << l.lat
      lons     << l.lon
      contents << l.content_for_infowindow
      num_machines << l.machines.size
    end

    [ids, lats, lons, contents, num_machines]
  end

  def newest_machine_name
    render plain: Location.find(params[:id]).newest_machine_xref.machine.name
  end

  def confirm
    l = Location.find(params[:id])
    l.confirm(current_user || nil)
    l
  end

  private

  def location_params
    params.require(:location).permit(:name, :street, :city, :state, :zip, :phone, :lat, :lon, :website, :zone_id, :region_id, :location_type_id, :description, :operator_id, :date_last_updated, :last_updated_by_user_id, :machine_ids, :is_stern_army, :ic_active)
  end
end
