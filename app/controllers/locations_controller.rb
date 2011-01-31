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
    respond_with(@locations = apply_scopes(Location).where('region_id = ?', @region.id))
  end

  def render_machines
    render :partial => 'locations/render_machines', :locals => {:location => Location.find(params[:id])}
  end

  def render_scores
    render :partial => 'locations/render_scores', :locals => {:lmx => LocationMachineXref.find(params[:id])}
  end
end
