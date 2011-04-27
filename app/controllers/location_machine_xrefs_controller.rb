class LocationMachineXrefsController < InheritedResources::Base
  respond_to :xml, :json, :html, :js, :rss
  has_scope :region

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

    LocationMachineXref.where(:location_id => params[:location_id], :machine => machine).first ||
      LocationMachineXref.create(:location_id => params[:location_id], :machine => machine)
  end

  def create_confirmation
    @lmx = LocationMachineXref.find(params[:id])
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
    @lmxs = apply_scopes(LocationMachineXref).includes(:location, :machine, :machine_score_xrefs)
    @lmxs.sort! {|a,b| b.id <=> a.id}
    respond_with(@lmxs)
  end

  def condition_update_confirmation
  end

  def remove_confirmation
  end
end
