class LocationMachineXrefsController < InheritedResources::Base
  respond_to :xml, :json, :html, :js, :rss
  has_scope :region
  before_action :authenticate_user!, only: %i[update_machine_condition create_confirmation remove_confirmation]

  def create
    machine = nil
    location = Location.find(params[:location_id])
    user = current_user.nil? ? nil : current_user

    if !params["add_machine_by_id_#{location.id}"].empty?
      machine = Machine.find(params["add_machine_by_id_#{location.id}"])
    elsif !params["add_machine_by_name_#{location.id}"].empty?
      machine = Machine.where(['lower(name) = ?', params["add_machine_by_name_#{location.id}"].downcase]).first

      if machine.nil?
        machine = Machine.new
        machine.name = params["add_machine_by_name_#{location.id}"]
        machine.save

        send_new_machine_notification(machine, location, user)
      end
    else
      # blank submit
      return
    end

    location.date_last_updated = Date.today
    location.last_updated_by_user_id = user.id
    location.save(validate: false)

    LocationMachineXref.where(['location_id = ? and machine_id = ?', location.id, machine.id]).first ||
      LocationMachineXref.create(location_id: location.id, machine_id: machine.id, user_id: user.id)
  end

  def create_confirmation
    @lmx = LocationMachineXref.find(params[:id])
  end

  def destroy
    lmx = LocationMachineXref.find_by_id(params[:id])

    user_id = current_user.nil? ? nil : current_user.id

    lmx.destroy(remote_ip: request.remote_ip, request_host: request.host, user_agent: request.user_agent, user_id: user_id) unless lmx&.nil?

    render nothing: true
  end

  def update_machine_condition
    id = params[:id]
    lmx = LocationMachineXref.find(id)

    condition = params["new_machine_condition_#{id}".to_sym]

    if condition =~ /<a href/
      lmx
    elsif ENV['RAKISMET_KEY']
      old_condition = lmx.condition

      lmx.condition = condition
      if lmx.spam?
        lmx.condition = old_condition
        nil
      else
        lmx.condition = old_condition
        lmx.update_condition(condition, remote_ip: request.remote_ip, request_host: request.host, user_agent: request.user_agent, user_id: current_user ? current_user.id : nil)
        lmx.location.date_last_updated = Date.today
        lmx.location.last_updated_by_user_id = current_user ? current_user.id : nil
        lmx.location.save(validate: false)
        lmx.location
      end
      lmx
    else
      lmx.update_condition(condition, remote_ip: request.remote_ip, request_host: request.host, user_agent: request.user_agent, user_id: current_user ? current_user.id : nil)
      lmx.location.date_last_updated = Date.today
      lmx.location.last_updated_by_user_id = current_user ? current_user.id : nil
      lmx.location.save(validate: false)
      lmx.location
      lmx
    end

    render nothing: true
  end

  def render_machine_condition
    render partial: 'location_machine_xrefs/update_machine_condition', locals: { lmx: LocationMachineXref.find(params[:id]) }
  end

  def render_machine_conditions
    lmx = LocationMachineXref.find(params[:id])
    render partial: 'locations/render_machine_conditions', locals: { conditions: lmx.sorted_machine_conditions, lmx: lmx }
  end

  def index
    @lmxs = apply_scopes(LocationMachineXref).order('location_machine_xrefs.id desc').limit(50).includes(:location, :machine, :machine_score_xrefs)
    respond_with(@lmxs)
  end

  def condition_update_confirmation; end

  def remove_confirmation; end

  private

  def event_params
    params.require(:location_machine_xref).permit(:machine_id, :location_id, :condition, :condition_date, :ip, :user_id)
  end
end
