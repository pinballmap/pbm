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

      api :POST, '/api/v1/users/signup.json', 'Signup a new user'
      description 'Signup a new user for the PBM'
      param :username, String, desc: 'New username', required: true
      param :email, String, desc: 'New email address', required: true
      param :password, String, desc: 'New password', required: true
      param :confirm_password, String, desc: 'New password confirmation', required: true
      def signup
        if params[:password].blank? || params[:confirm_password].blank?
          return_response('password can not be blank', 'errors')
          return
        end

        if params[:username].blank? || params[:email].blank?
          return_response('username and email are required fields', 'errors')
          return
        end

        if params[:password] != params[:confirm_password]
          return_response('your entered passwords do not match', 'errors')
          return
        end

        user = User.find_by_username(params[:username])
        if user
          return_response('This username already exists', 'errors')
          return
        end

        user = User.find_by_email(params[:email])
        if user
          return_response('This email address already exists', 'errors')
          return
        end

        user = User.new(email: params[:email], password: params[:password], password_confirmation: params[:confirm_password], username: params[:username])
        user.save ? return_response(user, 'user') : return_response(user.errors.full_messages.join(','), 'errors')
      end
    end
  end
end
