class LocationMachineXrefsController < ApplicationController
  has_scope :region
  before_action :authenticate_user!, except: %i[index render_machine_conditions render_machine_scores render_machine_tools]
  rate_limit to: 100, within: 10.minutes, only: :destroy
  rate_limit to: 100, within: 10.minutes, only: :update_machine_condition

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

    lmx = LocationMachineXref.unscoped.where([ "location_id = ? and machine_id = ?", location.id, machine.id ]).where.not(deleted_at: nil).where(deleted_at: 7.days.ago..Time.current).order(updated_at: :desc).first

    if lmx
      lmx.deleted_at = nil
      lmx.user_id = user.id
      lmx.save
      Location.increment_counter(:machine_count, location.id)
      lmx.create_user_submission
      if location.location_machine_xrefs.where(ic_enabled: true).present? && location.ic_active == false
        location.ic_active = true
      end
      location.date_last_updated = Date.today
      location.last_updated_by_user_id = user.id
      location.save(validate: false)
    else
      LocationMachineXref.where([ "location_id = ? and machine_id = ?", location.id, machine.id ]).where(deleted_at: nil).first ||
        LocationMachineXref.create(location_id: location.id, machine_id: machine.id, user_id: user.id)
    end
  end

  def destroy
    lmx = LocationMachineXref.find_by_id(params[:id])

    user_id = current_user&.id

    lmx.deleted_at = Time.now
    lmx.save

    lmx.destroy({ user_id: user_id }) unless lmx&.nil?

    render nothing: true
  end

  def update_machine_condition
    id = params[:id]
    lmx = LocationMachineXref.find(id)

    condition = params["new_machine_condition_#{id}".to_sym]

    if condition.match?(/<a href/)
      lmx
    else
      lmx.update_condition(condition, user_id: current_user&.id)
      lmx.location.date_last_updated = Date.today
      lmx.location.last_updated_by_user_id = current_user&.id
      lmx.location.save(validate: false)
      lmx.location
      lmx
    end

    render nothing: true
  end

  def not_found
    @record_not_found = true
  end

  def render_machine_tools
    @record_not_found = false
    logged_in = current_user ? "logged_in" : "logged_out"
    lmx = LocationMachineXref.find_by_id(params[:id]) or not_found

    if @record_not_found == true
      render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
    else
      render partial: "location_machine_xrefs/render_machine_tools", locals: { lmx: lmx, logged_in: logged_in }
    end
  end

  def render_machine_conditions
    @record_not_found = false
    lmx = LocationMachineXref.find_by_id(params[:id]) or not_found

    if @record_not_found == true
      render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
    else
      render partial: "location_machine_xrefs/render_machine_conditions", locals: { conditions: lmx.sorted_machine_conditions.includes([ :user ]), lmx: lmx }
    end
  end

  def render_machine_scores
    @record_not_found = false
    lmx = LocationMachineXref.find_by_id(params[:id]) or not_found

    if @record_not_found == true
      render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
    else
      render partial: "location_machine_xrefs/render_machine_scores", locals: { scores: lmx.sorted_machine_scores(current_user), highest: lmx.highest_machine_score(current_user), lmx: lmx }
    end
  end

  def index
    @lmxs = UserSubmission.where(submission_type: "new_lmx", created_at: "2019-05-03T07:00:00.00-07:00"..Date.today.end_of_day, deleted_at: nil).limit(50).order("created_at DESC")

    @lmxs = @lmxs.where(region_id: @region.id) if @region

    if params[:lat].present? || params[:lon].present?
      if params[:lat].blank? || params[:lon].blank?
        render file: Rails.public_path.join("404.html"), status: :not_found, layout: false and return
      end

      max_distance = params[:max_distance].present? ? params[:max_distance].to_i : 30
      @lmxs = @lmxs.near([ params[:lat], params[:lon] ], max_distance)
      @location_name = ""
    else
      location_ids = Array(params[:location_id]).select { |id| id.match?(/\A[0-9]+\z/) } if params[:location_id].present?
      @lmxs = @lmxs.where(location_id: location_ids) if location_ids&.any?
    end

    machine_ids = Array(params[:machine_id]).select { |id| id.match?(/\A[0-9]+\z/) } if params[:machine_id].present?
    @lmxs = @lmxs.where(machine_id: machine_ids) if machine_ids&.any?

    if params[:machine_id].present?
      machines = Machine.where(id: machine_ids)
      if machines.present?
        names = machines.map(&:name)
        overflow = names.size - 3
        @machine_name = " - #{names.first(3).join(', ')}#{overflow > 0 ? " and #{overflow} more #{'machine'.pluralize(overflow)}" : ''}"
      else
        render file: Rails.public_path.join("404.html"), status: :not_found, layout: false and return
      end
    else
      @machine_name = ""
    end

    if !params[:lat].present? && params[:location_id].present?
      if @lmxs.present?
        location_names = @lmxs.map(&:location_name).uniq
        location_overflow = location_names.size - 3
        @location_name = " - #{location_names.first(3).join(', ')}#{location_overflow > 0 ? " and #{location_overflow} more #{'location'.pluralize(location_overflow)}" : ''}"
      else
        render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
      end
    elsif !params[:lat].present?
      @location_name = ""
    end
  end

  def ic_toggle
    lmx = LocationMachineXref.find(params[:id])
    user = current_user
    lmx.toggle!(:ic_enabled)
    render partial: "location_machine_xrefs/ic_button", locals: { lmx: lmx }
    if (lmx.ic_enabled == true) && (lmx.location.ic_active != true)
      lmx.location.ic_active = true
      lmx.location.save
    elsif lmx.location.location_machine_xrefs.where(ic_enabled: true).blank?
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
