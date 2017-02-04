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

        unless user.confirmed_at
          return_response('User is not yet confirmed. Please follow emailed confirmation instructions.', 'errors')
          return
        end

        if user.is_disabled
          return_response('Your account is disabled. Please contact us if you think this is a mistake.', 'errors')
          return
        end

        return_response(user, 'user', [], [:username, :email, :authentication_token])
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
        user.save ? return_response(user, 'user', [], [:username, :email, :authentication_token]) : return_response(user.errors.full_messages.join(','), 'errors')
      end

      api :GET, '/api/v1/users/:id/profile_info.json', 'Fetch profile info for a user'
      param :id, Integer, desc: 'ID of location', required: true
      formats ['json']
      def profile_info
        user = User.find(params[:id])

        return_response(
          user,
          'profile_info',
          [],
          [:num_machines_added, :num_machines_removed, :num_locations_edited, :num_locations_suggested, :num_lmx_comments_left, :profile_list_of_edited_locations, :profile_list_of_high_scores, :created_at]
        )

        rescue ActiveRecord::RecordNotFound
          return_response('Failed to find user', 'errors')
      end
    end
  end
end
