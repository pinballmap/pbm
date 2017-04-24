class SuggestedLocationsController < InheritedResources::Base
  respond_to :xml, :json, :html, :js, :rss
  before_action :authenticate_user!

  def convert_to_location
    sl = SuggestedLocation.find(params[:id])

    location = Location.create(name: sl.name, street: sl.street, city: sl.city, state: sl.state, zip: sl.zip, phone: sl.phone, lat: sl.lat, lon: sl.lon, website: sl.website, region_id: sl.region_id, location_type_id: sl.location_type_id, operator_id: sl.operator_id)

    sl.machines.split(/\),\s*/).each do |machine_info|
      machine_info.strip!

      matches = machine_info.match(/(^.*)\((.*), (.*)/i)

      next if matches.nil?

      name, manufacturer, year = matches.captures
      name.strip!
      manufacturer.strip!
      year.strip!
      year.delete!(')', '')

      machine = Machine.find_by(name: name, year: year, manufacturer: manufacturer)

      LocationMachineXref.create(location_id: location.id, machine_id: machine.id) unless machine.nil?
    end

    sl.delete

    redirect_to rails_admin_path
  end
end
