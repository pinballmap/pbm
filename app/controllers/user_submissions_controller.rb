class UserSubmissionsController < ApplicationController
  has_scope :region

  def list_within_range
    unless params.dig(:boundsData, :sw, :lat)
      return render plain: "boundsData param (with sw/ne lat/lng) is required", status: :bad_request
    end

    bounds = [ params[:boundsData][:sw][:lat], params[:boundsData][:sw][:lng],
               params[:boundsData][:ne][:lat], params[:boundsData][:ne][:lng] ]

    user = current_user
    requested_types = params[:submission_type].blank? ? UserSubmission::ACTIVITY_SUBMISSION_TYPES + [ "new_msx" ] : Array(params[:submission_type])
    scope = UserSubmission.activity_scope(requested_types, user)

    user_submissions = scope.where.not(submission: nil)
                            .order("created_at DESC")
                            .with_coordinates
                            .within_bounding_box(bounds)
                            .includes([ :user, :location ])

    @pagy, @recent_activity = pagy(user_submissions)
    render partial: "maps/activity", locals: { pagy: @pagy }
  end
end
