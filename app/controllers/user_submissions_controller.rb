class UserSubmissionsController < ApplicationController
  has_scope :region

  def list_within_range
    bounds = [ params[:boundsData][:sw][:lat], params[:boundsData][:sw][:lng],
               params[:boundsData][:ne][:lat], params[:boundsData][:ne][:lng] ]
    user_submissions = UserSubmission.activity_feed(current_user)
                                     .with_coordinates
                                     .within_bounding_box(bounds)
                                     .includes([ :user, :location ])
    @pagy, @recent_activity = pagy(user_submissions)
    render partial: "maps/activity", locals: { pagy: @pagy }
  end
end
