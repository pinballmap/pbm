class UserSubmissionsController < ApplicationController
  has_scope :region

  def list_within_range
    bounds = [ params[:boundsData][:sw][:lat], params[:boundsData][:sw][:lng],
               params[:boundsData][:ne][:lat], params[:boundsData][:ne][:lng] ]
    user_submissions = UserSubmission.where.not(lat: nil)
                                     .where(submission_type: %w[new_lmx remove_machine new_condition confirm_location], created_at: "2019-05-03T07:00:00.00-07:00"..Date.today.end_of_day, deleted_at: nil)
                                     .within_bounding_box(bounds).limit(200)
    sorted_submissions = user_submissions.order("created_at DESC")
    render partial: "maps/nearby_activity", locals: { sorted_submissions: sorted_submissions }
  end
end
