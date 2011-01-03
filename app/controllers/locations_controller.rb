class LocationsController < InheritedResources::Base
  has_scope :by_location_name, :by_location_id, :by_machine_id, :by_machine_name, :by_city

  def autocomplete
    render :json => Location.find(:all, :conditions => ['name like ?', '%' + params[:term] + '%']).map { |l| l.name }
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
