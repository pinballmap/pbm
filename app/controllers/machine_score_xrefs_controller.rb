class MachineScoreXrefsController < ApplicationController
  has_scope :region
  before_action :authenticate_user!, except: %i[index]
  rate_limit to: 40, within: 5.minutes, only: :create

  def create
    score = params[:score]

    return if score.nil? || score.empty?

    score.gsub!(/[^0-9]/, "")

    return if score.nil? || score.empty? || score.to_i.zero?

    msx = MachineScoreXref.create(location_machine_xref_id: params[:location_machine_xref_id])

    msx.score = score
    msx.user = current_user
    msx.save
    msx.create_user_submission

    render nothing: true
  end

  def index
    if @region
      @msxs = UserSubmission.where(submission_type: "new_msx", region_id: @region.id, created_at: "2019-05-03T07:00:00.00-07:00"..Date.today.end_of_day).limit(50).order("created_at DESC")
    else
      @msxs = UserSubmission.where(submission_type: "new_msx", created_at: "2019-05-03T07:00:00.00-07:00"..Date.today.end_of_day).limit(50).order("created_at DESC")
    end
  end

  private

  def machine_score_xref_params
    params.require(:machine_score_xref).permit(:score, :location_machine_xref_id)
  end
end
