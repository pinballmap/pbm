class LocationMachineXrefsController < InheritedResources::Base
  respond_to :xml, :json, :html, :js, :rss
  has_scope :region

  def create
    machine = nil
    if !params[:add_machine_by_id].empty?
      machine = Machine.find(params[:add_machine_by_id])
    elsif !params[:add_machine_by_name].empty?
      machine = Machine.where(['lower(name) = ?', params[:add_machine_by_name].downcase]).first

      if machine.nil?
        machine = Machine.new
        machine.name = params[:add_machine_by_name]
        machine.save

        send_new_machine_notification(machine, Location.find(params[:location_id]))
      end
    else
      # blank submit
      return
    end

    LocationMachineXref.where(['location_id = ? and machine_id = ?', params[:location_id], machine.id]).first ||
      LocationMachineXref.create(location_id: params[:location_id], machine_id: machine.id)
  end

  def create_confirmation
    @lmx = LocationMachineXref.find(params[:id])
  end

  def destroy
    lmx = LocationMachineXref.find_by_id(params[:id])
    lmx.destroy(remote_ip: request.remote_ip, request_host: request.host, user_agent: request.user_agent) unless lmx.nil?

    render nothing: true
  end

  def update_machine_condition
    id = params[:id]
    lmx = LocationMachineXref.find(id)

    condition = params["new_machine_condition_#{id}".to_sym]

    if condition =~ /<a href/
      lmx
    elsif ENV['RAKISMET_KEY']
      lmx.condition = condition
      if lmx.spam?
        nil
      else
        lmx.update_condition(condition, remote_ip: request.remote_ip, request_host: request.host, user_agent: request.user_agent)
      end
      lmx
    else
      lmx.update_condition(condition, remote_ip: request.remote_ip, request_host: request.host, user_agent: request.user_agent)
      lmx
    end

    render nothing: true
  end

  def render_machine_condition
    render partial: 'location_machine_xrefs/update_machine_condition', locals: { lmx: LocationMachineXref.find(params[:id]) }
  end

  def render_machine_conditions
    lmx = LocationMachineXref.find(params[:id])
    render partial: 'locations/render_machine_conditions', locals: { conditions: lmx.sorted_machine_conditions.first(6), lmx: lmx }
  end

  def index
    @lmxs = apply_scopes(LocationMachineXref).order('location_machine_xrefs.id desc').limit(50).includes(:location, :machine, :machine_score_xrefs)
    respond_with(@lmxs)
  end

  def condition_update_confirmation
  end

  def remove_confirmation
  end
end
