class LocationMachineXrefsController < InheritedResources::Base
  respond_to :xml, :json, :html, :js, :rss
  has_scope :region
  before_action :authenticate_user!, except: %i[index show render_machine_conditions render_machine_tools]
  rate_limit to: 100, within: 20.minutes, only: :destroy
  rate_limit to: 50, within: 20.minutes, only: :update_machine_condition

  def create
    machine = nil
    location = Location.find(params[:location_id])
    user = current_user.nil? ? nil : current_user

    if !params["add_machine_by_id_#{location.id}"].empty?
      machine = Machine.find(params["add_machine_by_id_#{location.id}"])
    elsif !params["add_machine_by_name_#{location.id}"].empty?
      machine = Machine.where([ "lower(name) = ?", params["add_machine_by_name_#{location.id}"].downcase ]).first

      if machine.nil?
        render js: "show_new_machine_message();"
        return
      end
    else
      # blank submit
      return
    end

    location.date_last_updated = Date.today
    location.last_updated_by_user_id = user.id
    location.save(validate: false)

    LocationMachineXref.where([ "location_id = ? and machine_id = ?", location.id, machine.id ]).first ||
      LocationMachineXref.create(location_id: location.id, machine_id: machine.id, user_id: user.id)
  end

  def destroy
    lmx = LocationMachineXref.find_by_id(params[:id])

    user_id = current_user&.id

    lmx.ic_enabled = false
    lmx.save
    if lmx.location.location_machine_xrefs.where(ic_enabled: true).empty?
      lmx.location.ic_active = false
      lmx.location.save
    end

    lmx.destroy(remote_ip: request.headers['CF-CONNECTING-IP'], request_host: request.host, user_agent: request.user_agent, user_id: user_id) unless lmx&.nil?

    render nothing: true
  end

  def update_machine_condition
    id = params[:id]
    lmx = LocationMachineXref.find(id)

    condition = params["new_machine_condition_#{id}".to_sym]

    if condition.match?(/<a href/)
      lmx
    else
      lmx.update_condition(condition, remote_ip: request.headers['CF-CONNECTING-IP'], request_host: request.host, user_agent: request.user_agent, user_id: current_user&.id)
      lmx.location.date_last_updated = Date.today
      lmx.location.last_updated_by_user_id = current_user&.id
      lmx.location.save(validate: false)
      lmx.location
      lmx
    end

    render nothing: true
  end

  def render_machine_tools
    logged_in = current_user ? "logged_in" : "logged_out"

    render partial: "location_machine_xrefs/render_machine_tools", locals: { lmx: LocationMachineXref.find(params[:id]), logged_in: logged_in }
  end

  def render_machine_conditions
    lmx = LocationMachineXref.find(params[:id])
    render partial: "locations/render_machine_conditions", locals: { conditions: lmx.sorted_machine_conditions.includes([ :user ]), lmx: lmx }
  end

  def index
    @lmxs = apply_scopes(LocationMachineXref).order("location_machine_xrefs.id desc").limit(50).includes({ location: :region }, :machine, :user)
    @lmxs = @lmxs.where("machine_id = ?", params[:machine_id]) if params[:machine_id].present? && params[:machine_id].match?(/[0-9]+/)

    respond_with(@lmxs)
  end

  def ic_toggle
    lmx = LocationMachineXref.find(params[:id])
    user = current_user
    lmx.toggle!(:ic_enabled)
    render partial: "location_machine_xrefs/ic_button", locals: { lmx: lmx }
    if (lmx.ic_enabled == true) && (lmx.location.ic_active != true)
      lmx.location.ic_active = true
      lmx.location.save
    elsif lmx.location.location_machine_xrefs.where(ic_enabled: true).empty?
      lmx.location.ic_active = false
      lmx.location.save
    end
    lmx.create_ic_user_submission(user)
  end

  private

  def location_machine_xref_params
    params.require(:location_machine_xref).permit(:machine_id, :location_id, :ic_enabled)
  end
end
