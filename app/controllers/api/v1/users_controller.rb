module Api
  module V1
    class UsersController < InheritedResources::Base
      before_filter :allow_cors
      respond_to :json

      api :GET, '/api/v1/users/auth_details.json', 'Fetch auth info for a user'
      description "This info includes the user's API token."
      param :login, String, desc: "User's username or email address", required: true
      param :password, String, desc: "User's password", required: true
      def auth_details
        if params[:login].blank? || params[:password].blank?
          return_response('login and password are required fields', 'errors')
          return
        end

        user = User.find_by_username(params[:login]) || User.find_by_email(params[:login])

        unless user
          return_response('Unknown user', 'errors')
          return
        end

        unless user.valid_password?(params[:password])
          return_response('Incorrect password', 'errors')
          return
        end

        return_response(user, 'user')
      end
    end
  end
end
