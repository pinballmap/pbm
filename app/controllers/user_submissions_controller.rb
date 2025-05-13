class UserSubmissionsController < ApplicationController
  has_scope :region

  def list_within_range
    user_submissions = UserSubmission.where.not(lat: nil)
                                     .where(submission_type: %w[new_lmx remove_machine new_condition new_msx confirm_location], created_at: "2019-05-03T07:00:00.00-07:00"..Date.today.end_of_day)
                                     .near([ params[:lat], params[:lon] ], 100, order: false).limit(200)
    sorted_submissions = user_submissions.order("created_at DESC")
    render partial: "maps/nearby_activity", locals: { sorted_submissions: sorted_submissions }
  end
end
