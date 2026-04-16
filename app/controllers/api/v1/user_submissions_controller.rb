module Api
  module V1
    class UserSubmissionsController < ApplicationController
      skip_before_action :verify_authenticity_token

      before_action :allow_cors

      has_scope :region

      api :GET, "/api/v1/region/:region/user_submissions.json", "Fetch user submissions for a single region"
      api :GET, "/api/v1/user_submissions.json", "Fetch global user submissions feed"
      param :region, String, desc: "Name of the Region you want to see user submissions for", required: true
      param :submission_type, String, desc: "Type of submission to filter to. Multiple filters can be formatted as ;submission_type[]=remove_machine;submission_type[]=new_lmx etc", required: false
      param :user_id, Integer, desc: "Limits results to submissions from a single user", required: false
      param :user_name, String, desc: "Limits results to submissions from a single user", required: false
      param :restrict_to, String, desc: "Restrict this specific submission type to a single user. Requires user_id param to be included; if user_id param is not included, then the submission type specified here is excluded completely. This is used in the app to show submission types from everyone except the high scores only from the current user, or no scores if not signed in", required: false
      param :limit, Integer, desc: "Limit results to a quantity and include pagination metadata in response", required: false
      param :machine_id, Integer, desc: "Limit results by machine. Multiple machines can be chained as ;machine_id[]=111;machine_id[]=222 etc", required: false
      def index
        submission_type, submission_type_restrict = build_submission_types

        region_id = Region.find_by_name(params[:region].downcase).id if params[:region].present?

        user_submissions = apply_type_and_user_filter(base_user_submissions_scope, submission_type, submission_type_restrict)

        user_submissions = user_submissions.where(region_id: region_id) unless params[:region].blank?
        user_submissions = user_submissions.where(machine_id: params[:machine_id]) unless params[:machine_id].blank?

        if params[:limit].blank?
          user_submissions = user_submissions.limit(200).order("created_at DESC").includes([ :user, :location ])
        else
          @pagy, user_submissions = pagy(user_submissions.order("created_at desc").includes([ :user, :location ]).distinct)
          @pagy_hash = @pagy.data_hash(data_keys: %i[count first_url previous_url next_url page pages page_url previous next from to in last last_url limit options])
        end

        if !user_submissions.empty?
          respond_to do |format|
            if params[:limit].blank?
              format.json { return_response(user_submissions, "user_submissions", [], %i[location_operator_id user_operator_id admin_title contributor_rank], 200, [], nil) }
            else
              format.json { return_response(user_submissions, "user_submissions", [], %i[location_operator_id user_operator_id admin_title contributor_rank], 200, [], true) }
            end
          end
        else
          return_response("No user submissions.", "errors")
        end
      end

      api :GET, "/api/v1/user_submissions/location.json", "Fetch user submissions for a location"
      param :id, Integer, desc: "ID of location", required: true
      param :submission_type, String, desc: "Type of submission to filter to. Multiple filters can be formatted as ;submission_type[]=remove_machine;submission_type[]=new_lmx etc.", required: false
      param :user_id, Integer, desc: "Limits results to submissions from a single user", required: false
      param :user_name, String, desc: "Limits results to submissions from a single user", required: false
      param :restrict_to, String, desc: "Restrict this specific submission type to a single user. Requires user_id param to be included; if user_id param is not included, then the submission type specified here is excluded completely. This is used in the app to show submission types from everyone except the high scores only from the current user, or no scores if not signed in", required: false
      param :limit, Integer, desc: "Limit results to a quantity and include pagination metadata in response", required: false
      param :machine_id, Integer, desc: "Limit results by machine. Multiple machines can be chained as ;machine_id[]=111;machine_id[]=222 etc", required: false
      formats [ "json" ]
      def location
        location = Location.find(params[:id])

        submission_type, submission_type_restrict = build_submission_types

        user_submissions = apply_type_and_user_filter(base_user_submissions_scope.where(location_id: location), submission_type, submission_type_restrict)

        user_submissions = user_submissions.where(machine_id: params[:machine_id]) unless params[:machine_id].blank?

        if params[:limit].blank?
          user_submissions = user_submissions.limit(200).order("created_at DESC").includes([ :user, :location ])
        else
          @pagy, user_submissions = pagy(user_submissions.order("created_at desc").includes([ :user, :location ]).distinct)
          @pagy_hash = @pagy.data_hash(data_keys: %i[count first_url previous_url next_url page pages page_url previous next from to in last last_url limit options])
        end

        if !user_submissions.empty?
          respond_to do |format|
            if params[:limit].blank?
              format.json { return_response(user_submissions, "user_submissions", [], %i[location_operator_id user_operator_id admin_title contributor_rank], 200, [], nil) }
            else
              format.json { return_response(user_submissions, "user_submissions", [], %i[location_operator_id user_operator_id admin_title contributor_rank], 200, [], true) }
            end
          end
        else
          return_response("No user submissions for this location.", "errors")
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
        total_user_submission_count = Rails.cache.fetch("total_user_submission_count_cache", expires_in: 1.hour) do
          UserSubmission.where(deleted_at: nil).count
        end
        return_response(total_user_submission_count, "total_user_submission_count")
      end

      api :GET, "/api/v1/user_submissions/total_user_submission_count_week.json", "Fetch total count of user submissions for the past week"
      description "Fetch total count of user submissions"
      formats [ "json" ]
      def total_user_submission_count_week
        total_user_submission_count_week = Rails.cache.fetch("total_user_submission_count_week_cache", expires_in: 1.hour) do
          UserSubmission.where("created_at >= ?", 1.week.ago).where(deleted_at: nil).count
        end
        return_response(total_user_submission_count_week, "total_user_submission_count_week")
      end

      api :GET, "/api/v1/user_submissions/top_users.json", "Fetch top 25 users by submission count"
      description "Fetch top 25 users by submission count"
      formats [ "json" ]
      def top_users
        top_users = Rails.cache.fetch("top_users_cache", expires_in: 1.hour) do
          User.where("user_submissions_count > 0").select([ "id", "username", "user_submissions_count" ]).order(user_submissions_count: :desc).limit(25)
        end

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
      param :user_id, Integer, desc: "Limits results to submissions from a single user", required: false
      param :user_name, String, desc: "Limits results to submissions from a single user", required: false
      param :restrict_to, String, desc: "Restrict this specific submission type to a single user. Requires user_id param to be included; if user_id param is not included, then the submission type specified here is excluded completely. This is used in the app to show submission types from everyone except the high scores only from the current user, or no scores if not signed in", required: false
      param :limit, Integer, desc: "Limit results to a quantity and include pagination metadata in response", required: false
      param :machine_id, Integer, desc: "Limit results by machine. Multiple machines can be chained as ;machine_id[]=111;machine_id[]=222 etc", required: false
      def list_within_range
        max_distance = params[:max_distance].blank? ? MAX_MILES_TO_SEARCH_FOR_USER_SUBMISSIONS : [ 250, params[:max_distance].to_i ].min

        submission_type, submission_type_restrict = build_submission_types

        user_submissions = apply_type_and_user_filter(base_user_submissions_scope, submission_type, submission_type_restrict)

        user_submissions = user_submissions.where(region_id: params[:region_id]) unless params[:region_id].blank?
        user_submissions = user_submissions.where(machine_id: params[:machine_id]) unless params[:machine_id].blank?
        user_submissions = user_submissions.where(created_at: params[:min_date_of_submission].to_date.beginning_of_day..Date.today.end_of_day) if params[:min_date_of_submission]

        if params[:limit].blank?
          user_submissions = user_submissions.near([ params[:lat], params[:lon] ], max_distance, order: "created_at desc").includes([ :user, :location ]).limit(200)
        else
          @pagy, user_submissions = pagy(user_submissions.near([ params[:lat], params[:lon] ], max_distance, order: "created_at desc").includes([ :user, :location ]).distinct)
          @pagy_hash = @pagy.data_hash(data_keys: %i[count first_url previous_url next_url page pages page_url previous next from to in last last_url limit options])
        end

        if !user_submissions.empty?
          respond_to do |format|
            if params[:limit].blank?
              format.json { return_response(user_submissions, "user_submissions", [], %i[location_operator_id user_operator_id admin_title contributor_rank], 200, [], nil) }
            else
              format.json { return_response(user_submissions, "user_submissions", [], %i[location_operator_id user_operator_id admin_title contributor_rank], 200, [], true) }
            end
          end
        else
          return_response("No user submissions found within radius.", "errors")
        end
      end

      private

      def base_user_submissions_scope
        UserSubmission.where.not(submission: nil).where.not(location_name: nil).where(deleted_at: nil)
      end

      def build_submission_types
        if params[:submission_type].blank?
          types = %w[add_location new_lmx remove_machine new_condition new_msx confirm_location]
          if params[:restrict_to].present?
            restrict = params[:restrict_to]
            types = types.excluding(restrict)
          end
        else
          types = Array(params[:submission_type])
          restrict = nil
        end

        [ types, restrict ]
      end

      def apply_type_and_user_filter(scope, submission_type, submission_type_restrict)
        has_user = params[:user_id].present? || params[:user_name].present?
        user_field = params[:user_id].present? ? { user_id: params[:user_id] } : { user_name: params[:user_name] }

        if params[:restrict_to].present? && has_user
          type_condition = UserSubmission.where(submission_type: submission_type)
                                         .or(UserSubmission.where(submission_type: submission_type_restrict, **user_field))
          scope.merge(type_condition)
        elsif has_user
          scope.where(submission_type: submission_type, **user_field)
        else
          scope.where(submission_type: submission_type)
        end
      end
    end
  end
end
