class UserSubmissionsController < ApplicationController
  has_scope :region

  def list_within_range
    bounds = [ params[:boundsData][:sw][:lat], params[:boundsData][:sw][:lng],
               params[:boundsData][:ne][:lat], params[:boundsData][:ne][:lng] ]
    user_submissions = UserSubmission.activity_feed
                                     .with_coordinates
                                     .within_bounding_box(bounds)
                                     .includes([ :user, :location ])
    @pagy, sorted_submissions = pagy(user_submissions)
    render partial: "maps/activity", locals: { sorted_submissions: sorted_submissions, pagy: @pagy }
  end
end
