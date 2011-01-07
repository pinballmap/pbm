class LocationsController < InheritedResources::Base
  has_scope :by_location_name, :by_location_id, :by_machine_id, :by_machine_name, :by_city, :by_zone_id

  def autocomplete
    render :json => Location.find(:all, :conditions => ['name like ?', '%' + params[:term] + '%']).map { |l| l.name }
  end

  def update_condition
    lmx = LocationMachineXref.find(:all, :conditions => ['location_id = ? and machine_id = ?', params[:location_id], params[:machine_id]])
    lmx.condition = params[:condition]
    lmx.condition_date = Time.now
  end

  def remove_machine
    LocationMachineXref.delete(:location_id => Location.find(params[:location_id]).id, :machine_id => Machine.find(params[:machine_id]).id)
  end

  def add_machine
    machine = nil
    if(!params[:add_machine_by_id].empty?)
      machine = Machine.find(params[:add_machine_by_id])
    elsif (!params[:add_machine_by_name].empty?)
      machine = Machine.find_or_create_by_name(params[:add_machine_by_name])
    else
      #blank submit
      return
    end

    LocationMachineXref.create(:location => Location.find(params[:location_id]), :machine => machine)
  end

  def index
    @locations = apply_scopes(Location).all

    render
  end
end
