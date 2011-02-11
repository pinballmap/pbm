class LocationMachineXrefsController < InheritedResources::Base
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
end
