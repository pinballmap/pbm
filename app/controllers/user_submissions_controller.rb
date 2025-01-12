class UserSubmissionsController < InheritedResources::Base
  respond_to :html, :xml, :json, :rss, only: %i[index show]
  has_scope :region

  def create
    @user_submission = UserSubmission.new(user_submission_params)
    if @user_submission.save
      redirect_to @user_submission, notice: 'UserSubmission was successfully created.'
    else
      render action: 'new'
    end
  end

  def list_within_range
    user_submissions = UserSubmission.where.not(lat: nil)
                                     .where(submission_type: %w[new_lmx remove_machine new_condition new_msx confirm_location], created_at: '2019-05-03T07:00:00.00-07:00'..Date.today.end_of_day)
                                     .near([params[:lat], params[:lon]], 100, order: false).limit(200)
    sorted_submissions = user_submissions.order('created_at DESC')
    render partial: 'maps/nearby_activity', locals: { sorted_submissions: sorted_submissions }
  end

  private

  def user_submission_params
    params.require(:user_submission).permit(:region_id, :user, :user_name, :user_id, :submission_type, :submission, :location, :lat, :lon, :location_name, :location_id, :city_name, :comment, :high_score, :machine, :machine_id, :machine_name)
  end
end
