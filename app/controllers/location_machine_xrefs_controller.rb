class LocationMachineXrefsController < InheritedResources::Base
  respond_to :xml, :json, :html, :js, :rss

  def create
    machine = nil
    if(!params[:add_machine_by_id].empty?)
      machine = Machine.find(params[:add_machine_by_id])
    elsif (!params[:add_machine_by_name].empty?)
      machine = Machine.find_or_create_by_name(params[:add_machine_by_name])
    else
      #blank submit
      return
    end

    LocationMachineXref.where(:location => Location.find(params[:location_id]), :machine => machine).first ||
      LocationMachineXref.create(:location => Location.find(params[:location_id]), :machine => machine)
  end

  def destroy
    LocationMachineXref.find(params[:id]).destroy
  end

  def update_machine_condition
    id = params[:id]

    lmx = LocationMachineXref.find(id)
    lmx.condition = params["new_machine_condition_#{id}".to_sym]
    lmx.condition_date = Time.now
    lmx.save
  end

  def index
    @lmxs = apply_scopes(LocationMachineXref).includes(:location)
    respond_with(@lmxs)
  end
end
