class UserSubmissionsController < ApplicationController
  has_scope :region

  def list_within_range
    bounds = [ params[:boundsData][:sw][:lat], params[:boundsData][:sw][:lng],
               params[:boundsData][:ne][:lat], params[:boundsData][:ne][:lng] ]

    user = current_user
    requested_types = params[:submission_type].blank? ? UserSubmission::ACTIVITY_SUBMISSION_TYPES + [ "new_msx" ] : Array(params[:submission_type])
    general_types = requested_types.excluding("new_msx")
    include_msx = requested_types.include?("new_msx") && user.present?

    scope = if general_types.any? && include_msx
      UserSubmission.where(submission_type: general_types, deleted_at: nil)
                    .or(UserSubmission.where(submission_type: "new_msx", user: user, deleted_at: nil))
    elsif include_msx
      UserSubmission.where(submission_type: "new_msx", user: user, deleted_at: nil)
    elsif general_types.any?
      UserSubmission.where(submission_type: general_types, deleted_at: nil)
    else
      UserSubmission.none
    end

    user_submissions = scope.where.not(submission: nil)
                            .order("created_at DESC")
                            .with_coordinates
                            .within_bounding_box(bounds)
                            .includes([ :user, :location ])

    @pagy, @recent_activity = pagy(user_submissions)
    render partial: "maps/activity", locals: { pagy: @pagy }
  end
end
