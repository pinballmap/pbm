module Api
  module V1
    class UsersController < InheritedResources::Base
      before_filter :allow_cors
      respond_to :json

      api :GET, '/api/v1/users/auth_details.json', 'Fetch auth info for a user'
      description "This info includes the user's API token."
      param :user_email, String, desc: "User's email address -- this field or username are required", required: false
      param :username, String, desc: "User's username -- this field or username are required", required: false
      param :password, String, desc: "User's password", required: true
      def auth_details
        if (params[:user_email].blank? && params[:username].blank?) || params[:password].blank?
          return_response('(username or user_email) and password are required fields', 'errors')
          return
        end

        user = nil
        if params[:user_email]
          user = User.find_by_email(params[:user_email])
        else
          user = User.find_by_username(params[:username])
        end

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
