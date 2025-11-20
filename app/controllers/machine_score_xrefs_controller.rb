class MachineScoreXrefsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  has_scope :region
  before_action :authenticate_user!, except: %i[index]
  rate_limit to: 40, within: 5.minutes, only: :create

  def create
    score = params[:score]

    return if score.blank?

    score.gsub!(/[^0-9]/, "")

    return if score.blank? || score.to_i.zero?

    msx = MachineScoreXref.new(location_machine_xref_id: params[:location_machine_xref_id])

    msx.score = score
    msx.user = current_user
    msx.save
    msx.create_user_submission

    render nothing: true
  end

  def index
    if @region
      @msxs = UserSubmission.where(submission_type: "new_msx", region_id: @region.id, created_at: "2019-05-03T07:00:00.00-07:00"..Date.today.end_of_day, deleted_at: nil).limit(50).order("created_at DESC")
    else
      @msxs = UserSubmission.where(submission_type: "new_msx", created_at: "2019-05-03T07:00:00.00-07:00"..Date.today.end_of_day, deleted_at: nil).limit(50).order("created_at DESC")
    end
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

    us.update(high_score: score, submission: "#{us.user_name} added a high score of #{number_with_precision(score, precision: 0, delimiter: ',')} on #{us.machine_name} at #{us.location_name} in #{us.city_name}.") if user && (user.id == us.user_id)

    msx.update(machine_score_xref_params) if user && (user.id == msx.user_id)

    render nothing: true
  end

  private

  def machine_score_xref_params
    params.permit(:score, :location_machine_xref_id)
  end
end
