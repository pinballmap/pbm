module Api
  module V1
    class UserSubmissionsController < InheritedResources::Base
      before_filter :allow_cors
      respond_to :json

      has_scope :region

      api :GET, '/api/v1/region/:region/user_submissions.json', 'Fetch user submissions for a single region'
      param :region, String, desc: 'Name of the Region you want to see user submissions for', required: true
      def index
        user_submissions = apply_scopes(UserSubmission)
        user_submissions = user_submissions.select { |s| s.submission_type == UserSubmission::REMOVE_MACHINE_TYPE }

        return_response(user_submissions, 'user_submissions')
      end
    end
  end
end
