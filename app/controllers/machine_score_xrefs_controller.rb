class MachineScoreXrefsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  has_scope :region
  before_action :authenticate_user!, except: %i[index new]
  rate_limit to: 80, within: 2.minutes, only: :create, name: "msx_create"

  def new
    @all_machines = Machine.select_option_data
    @life_list_machine_ids = current_user ? current_user.user_machine_xrefs.pluck(:machine_id) : []
  end

  def create
    score = params[:score]

    if params[:location_machine_xref_id].present?
      return if score.blank?

      score.gsub!(/[^0-9]/, "")

      return if score.blank? || score.to_i.zero?

      machine_id = LocationMachineXref.where(id: params[:location_machine_xref_id]).pluck(:machine_id).first
      msx = MachineScoreXref.new(location_machine_xref_id: params[:location_machine_xref_id], score: score, user: current_user, machine_id: machine_id)
      msx.save
      msx.create_user_submission
      UserMachineXref.find_or_create_by(user: current_user, machine_id: machine_id)
      render nothing: true
    else
      if score.blank?
        redirect_to add_score_path, alert: "Score can't be blank."
        return
      end

      score.gsub!(/[^0-9]/, "")

      if score.blank? || score.to_i.zero?
        redirect_to add_score_path, alert: "Score must be a numeric value."
        return
      end

      machine_id = params[:machine_id].to_i
      msx = MachineScoreXref.new(score: score, user: current_user, machine_id: machine_id)
      if msx.save
        msx.create_user_submission
        UserMachineXref.find_or_create_by(user: current_user, machine_id: machine_id)
        redirect_to add_score_path, notice: "Score added!"
      else
        redirect_to add_score_path, alert: "Failed to save score."
      end
    end
  end

  def index
    @msxs = UserSubmission.includes(:machine, :location).where(submission_type: "new_msx", created_at: "2019-05-03T07:00:00.00-07:00"..Date.today.end_of_day, deleted_at: nil).limit(50).order("created_at DESC")
    @msxs = @msxs.where(region_id: @region.id) if @region.present?
  end

  def destroy
    user = current_user.nil? ? nil : current_user
    msx = MachineScoreXref.find(params[:id])
    us = UserSubmission.find_by(machine_score_xref_id: msx.id)

    if user && (user.id == msx.user_id)
      us.deleted_at = Time.now
      us.save
      msx.destroy
    end

    render nothing: true
  end

  def update
    user = current_user.nil? ? nil : current_user
    msx = MachineScoreXref.find(params[:id])
    us = UserSubmission.find_by(machine_score_xref_id: msx.id)

    score = params[:score]

    return if score.blank?

    score.gsub!(/[^0-9]/, "")

    return if score.blank? || score.to_i.zero?

    us.high_score = score
    us.submission = "#{us.user_name} added a high score of #{number_with_precision(score, precision: 0, delimiter: ',')} on #{us.machine_name} at #{us.location_name} in #{us.city_name}" if user && (user.id == us.user_id) && us.user_name.present? && us.machine_name.present? && us.location_name.present? && us.city_name.present?
    us.save

    msx.update(machine_score_xref_params) if user && (user.id == msx.user_id)

    render nothing: true
  end

  private

  def machine_score_xref_params
    params.permit(:score, :location_machine_xref_id)
  end
end
