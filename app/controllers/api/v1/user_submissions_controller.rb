module Api
  module V1
    class UserSubmissionsController < ApplicationController
      skip_before_action :verify_authenticity_token

      before_action :allow_cors

      has_scope :region

      api :GET, "/api/v1/region/:region/user_submissions.json", "Fetch user submissions for a single region"
      param :region, String, desc: "Name of the Region you want to see user submissions for", required: true
      param :submission_type, String, desc: "Type of submission to filter to. Multiple filters can be formatted as ;submission_type[]=remove_machine;submission_type[]=new_lmx etc.", required: false
      def index
        submission_type = params[:submission_type].blank? ? %w[new_lmx remove_machine new_condition new_msx confirm_location] : params[:submission_type]

        region_id = Region.where(name: params[:region]).pluck(:id).first

        user_submissions = UserSubmission.where(submission_type: submission_type, region_id: region_id, created_at: "2019-05-03T07:00:00.00-07:00"..Date.today.end_of_day).limit(200).order("created_at DESC")

        return_response(user_submissions, "user_submissions")
      end

      api :GET, "/api/v1/user_submissions/location.json", "Fetch user submissions for a location"
      param :id, Integer, desc: "ID of location", required: true
      param :submission_type, String, desc: "Type of submission to filter to. Multiple filters can be formatted as ;submission_type[]=remove_machine;submission_type[]=new_lmx etc.", required: false
      param :limit, Integer, desc: "Limit results to a quantity and include pagination metadata in response", required: false
      formats [ "json" ]
      def location
        location = Location.find(params[:id])

        submission_type = params[:submission_type].blank? ? %w[new_lmx remove_machine new_condition new_msx confirm_location] : params[:submission_type]

        if params[:limit].blank?
          user_submissions = UserSubmission.where(location_id: location, submission_type: submission_type, created_at: "2019-05-03T07:00:00.00-07:00"..Date.today.end_of_day, deleted_at: nil).limit(200).order("created_at DESC")
        else
          @pagy, user_submissions = pagy(UserSubmission.where(location_id: location, submission_type: submission_type, created_at: "2019-05-03T07:00:00.00-07:00"..Date.today.end_of_day, deleted_at: nil).order("created_at desc").distinct, limit_extra: true)

          @pagy_metadata = pagy_metadata(@pagy)
        end

        if !user_submissions.empty?
          respond_to do |format|
            if params[:limit].blank?
              format.json { return_response(user_submissions, "user_submissions", [], [], 200, [], nil) }
            else
              format.json { return_response(user_submissions, "user_submissions", [], [], 200, [], true) }
            end
          end
        else
          return_response("No user submissions found within radius.", "errors")
        end
      rescue ActiveRecord::RecordNotFound
        return_response("Failed to find location", "errors")
      end

      api :GET, "/api/v1/user_submissions/delete_location.json", "Fetch list of deleted locations from the past year"
      formats [ "json" ]
      def delete_location
        except = %i[user_id machine_id comment user_name location_name machine_name high_score city_name lat lon]
        user_submissions = UserSubmission.where(created_at: (1.year.ago)..(Date.today.end_of_day), submission_type: UserSubmission::DELETE_LOCATION_TYPE).order("created_at DESC")

        return_response(user_submissions, "user_submissions", [], [], 200, except)
      rescue ActiveRecord::RecordNotFound
        return_response("Failed to find location", "errors")
      end

      api :GET, "/api/v1/user_submissions/total_user_submission_count.json", "Fetch total count of user submissions"
      description "Fetch total count of user submissions"
      formats [ "json" ]
      def total_user_submission_count
        return_response({ total_user_submission_count: UserSubmission.count }, nil)
      end

      api :GET, "/api/v1/user_submissions/top_users.json", "Fetch top 25 users by submission count"
      description "Fetch top 25 users by submission count"
      formats [ "json" ]
      def top_users
        top_users = User.where("user_submissions_count > 0").select([ "id", "username", "user_submissions_count" ]).order(user_submissions_count: :desc).limit(25)

        return_response(top_users, nil, [], %i[id username user_submissions_count])
      end

      MAX_MILES_TO_SEARCH_FOR_USER_SUBMISSIONS = 30

      api :GET, "/api/v1/user_submissions/list_within_range.json", "Fetch user submissions within N miles of provided lat/lon"
      param :lat, String, desc: "Latitude", required: true
      param :lon, String, desc: "Longitude", required: true
      param :max_distance, String, desc: 'Closest location within "max_distance" miles, max of 250', required: false
      param :min_date_of_submission, String, desc: "Earliest date to consider updates from, format YYYY-MM-DD", required: false
      param :submission_type, String, desc: "Type of submission to filter to. Multiple filters can be formatted as ;submission_type[]=remove_machine;submission_type[]=new_lmx etc.", required: false
      param :region_id, String, desc: "Limit results to a region", required: false
      param :limit, Integer, desc: "Limit results to a quantity and include pagination metadata in response", required: false
      def list_within_range
        if params[:max_distance].blank?
          max_distance = MAX_MILES_TO_SEARCH_FOR_USER_SUBMISSIONS
        else
          max_distance = [ 250, params[:max_distance].to_i ].min
        end

        submission_type = params[:submission_type].blank? ? %w[new_lmx remove_machine new_condition new_msx confirm_location] : params[:submission_type]

        user_submissions = UserSubmission.where.not(lat: nil).where(submission_type: submission_type, deleted_at: nil)

        user_submissions = user_submissions.where(region_id: params[:region_id]) unless params[:region_id].blank?

        min_date_of_submission = params[:min_date_of_submission] ? params[:min_date_of_submission].to_date.beginning_of_day : "2019-05-03T07:00:00.00-07:00"

        user_submissions = user_submissions.where(created_at: min_date_of_submission..Date.today.end_of_day) if min_date_of_submission

        if params[:limit].blank?
          user_submissions = user_submissions.near([ params[:lat], params[:lon] ], max_distance, order: "created_at desc").limit(200)
        else
          @pagy, user_submissions = pagy(user_submissions.near([ params[:lat], params[:lon] ]).order("created_at desc").distinct, limit_extra: true)

          @pagy_metadata = pagy_metadata(@pagy)
        end

        if !user_submissions.empty?
          respond_to do |format|
            if params[:limit].blank?
              format.json { return_response(user_submissions, "user_submissions", [], [], 200, [], nil) }
            else
              format.json { return_response(user_submissions, "user_submissions", [], [], 200, [], true) }
            end
          end
        else
          return_response("No user submissions found within radius.", "errors")
        end
      end
    end
  end
end
