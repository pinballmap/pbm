module Api
  module V1
    class UsersController < ApplicationController
      TLD_TYPOS = {
        "ocm" => "com", "cmo" => "com", "omc" => "com", "moc" => "com", "mco" => "com",
        "vom" => "com", "xom" => "com", "cpm" => "com", "con" => "com", "cob" => "com",
        "comt" => "com", "comm" => "com", "comn" => "com", "coms" => "com", "corm" => "com",
        "ney" => "net", "ner" => "net", "ned" => "net", "met" => "net", "nte" => "net",
        "orh" => "org", "orv" => "org", "ogr" => "org", "rog" => "org", "oeg" => "org"
      }.freeze
      skip_before_action :verify_authenticity_token

      before_action :allow_cors
      rate_limit to: 50, within: 2.minutes, only: :profile_info, name: "api_users_profile_info"
      rate_limit to: 10, within: 1.minute, only: [ :forgot_password, :resend_confirmation, :auth_details, :destroy, :signup, :update_password, :update_email ], name: "api_users_auth_actions"

      api :GET, "/api/v1/users/:id/list_fave_locations.json", "Fetch list of favorite locations"
      description "Fetch list of favorite locations"
      param :id, Integer, desc: "ID of user", required: true
      formats [ "json" ]
      def list_fave_locations
        user = User.find(params[:id])
        locations = user.user_fave_locations.includes([ location: %i[location_type machines] ])

        return_response(
          locations,
          "user_fave_locations",
          [ location: { include: { location_type: {}, machines: { except: %i[is_active created_at updated_at machine_group_id ipdb_id opdb_id opdb_img opdb_img_height opdb_img_width display machine_type machine_display ic_eligible] } },
          except: %i[phone website created_at updated_at zone_id region_id description operator_id is_stern_army country is_active] } ]
        )
      rescue ActiveRecord::RecordNotFound
        return_response("Unknown user", "errors")
      end

      api :GET, "/api/v1/users/total_user_count.json", "Fetch total count of users"
      description "Fetch total count of users"
      formats [ "json" ]
      def total_user_count
        return_response({ total_user_count: User.count }, nil)
      end

      api :POST, "/api/v1/users/:id/add_fave_location.json", "Adds a location to your fave list"
      description "Adds a location to your fave list"
      param :id, Integer, desc: "ID of user", required: true
      param :location_id, Integer, desc: "ID of location to add", required: true
      formats [ "json" ]
      def add_fave_location
        user = User.find(params[:id])
        location = Location.find(params[:location_id])

        if user.authentication_token != params[:user_token]
          return_response("Unauthorized user update.", "errors")
          return
        end

        if UserFaveLocation.where(user: user, location: location).count.positive?
          return_response("This location is already saved as a fave.", "errors")
          return
        end

        UserFaveLocation.create(user: user, location: location)

        return_response("Successfully added fave", "success")
      rescue ActiveRecord::RecordNotFound
        return_response("Unknown asset", "errors")
      end

      api :POST, "/api/v1/users/:id/remove_fave_location.json", "Removes a location from your fave list"
      description "Removes a location from your fave list"
      param :id, Integer, desc: "ID of user", required: true
      param :location_id, Integer, desc: "ID of location to remove", required: true
      formats [ "json" ]
      def remove_fave_location
        user = User.find(params[:id])
        location = Location.find(params[:location_id])

        if user.authentication_token != params[:user_token]
          return_response("Unauthorized user update.", "errors")
          return
        end

        UserFaveLocation.where(user: user, location: location).destroy_all

        return_response("Successfully removed fave", "success")
      rescue ActiveRecord::RecordNotFound
        return_response("Unknown asset", "errors")
      end

      api :GET, "/api/v1/users/auth_details.json", "Fetch auth info for a user"
      description "This info includes the user's API token."
      param :login, String, desc: "User's username or email address", required: true
      param :password, String, desc: "User's password", required: true
      def auth_details
        if params[:login].blank? || params[:password].blank?
          return_response("login and password are required fields", "errors")
          return
        end

        user = User.where("lower(username) = ?", params[:login].downcase).first || User.where("lower(email) = ?", params[:login].downcase).first

        unless user
          return_response("Unknown user", "errors")
          return
        end

        unless user.valid_password?(params[:password])
          return_response("Incorrect password", "errors")
          return
        end

        unless user.confirmed_at
          return_response("User is not yet confirmed. Please follow emailed confirmation instructions.", "errors")
          return
        end

        if user.is_disabled
          render json: { error: ACCOUNT_DISABLED_MSG }, status: :unauthorized
          return
        end

        return_response(user, "user", [], %i[username email authentication_token])
      end

      api :POST, "/api/v1/users/forgot_password.json", "Password retrieval"
      description "Reset a forgotten password"
      param :identification, String, desc: "A username or email address", required: true
      def forgot_password
        if params[:identification].blank?
          return_response("Please send an email or username to use this feature", "errors")
          return
        end

        user = User.where("lower(username) = ?", params[:identification].downcase).first || User.where("lower(email) = ?", params[:identification].downcase).first

        unless user
          return_response("Can not find a user associated with this email or username", "errors")
          return
        end

        user.send_reset_password_instructions
        return_response("Password reset request successful.", "msg")
      end

      api :POST, "/api/v1/users/resend_confirmation.json", "Resend confirmation"
      description "Resend an account confirmation"
      param :identification, String, desc: "A username or email address", required: true
      def resend_confirmation
        if params[:identification].blank?
          return_response("Please send an email or username to use this feature", "errors")
          return
        end

        user = User.where("lower(username) = ?", params[:identification].downcase).first || User.where("lower(email) = ?", params[:identification].downcase).first

        unless user
          return_response("Can not find a user associated with this email or username", "errors")
          return
        end

        user.send_confirmation_instructions
        return_response("Confirmation info resent.", "msg")
      end

      api :POST, "/api/v1/users/signup.json", "Signup a new user"
      description "Signup a new user for the PBM"
      param :username, String, desc: "New username", required: true
      param :email, String, desc: "New email address", required: true
      param :password, String, desc: "New password", required: true
      param :confirm_password, String, desc: "New password confirmation", required: true
      def signup
        if params[:password].blank? || params[:confirm_password].blank?
          return_response("password can not be blank", "errors")
          return
        end

        if params[:username].blank? || params[:email].blank?
          return_response("username and email are required fields", "errors")
          return
        end

        if params[:password] != params[:confirm_password]
          return_response("your entered passwords do not match", "errors")
          return
        end

        user = User.find_by_username(params[:username])
        if user
          return_response("This username already exists", "errors")
          return
        end

        tld = params[:email].split(".").last&.downcase&.gsub(/[^a-z]/, "")
        if (suggestion = TLD_TYPOS[tld])
          return_response(".#{tld} looks like an email typo. Did you mean .#{suggestion}?", "errors")
          return
        end

        user = User.find_by_email(params[:email])
        if user
          return_response("This email address already exists", "errors")
          return
        end

        user = User.new(email: params[:email], password: params[:password], password_confirmation: params[:confirm_password], username: params[:username])
        user.save ? return_response(user, "user", [], %i[username email authentication_token]) : return_response(user.errors.full_messages.join(","), "errors")
      end

      api :GET, "/api/v1/users/:id/profile_info.json", "Fetch profile info for a user"
      param :id, Integer, desc: "ID of user", required: true
      param :new_score_list_only, Integer, desc: "When present, the old high score list is gone (recent 50); only showing the new list of highest high score per machine, all scores per machine, and average and count", required: false
      param :life_list, Integer, desc: "When present, returns the life list (all machines the user has played) with associated score data instead of profile_machine_scores_stats", required: false
      formats [ "json" ]
      def profile_info
        user = User.find(params[:id])
        includes = %i[admin_rank_int admin_title contributor_rank_int contributor_rank flag num_total_submissions num_machines_added num_machines_removed num_locations_edited num_locations_suggested num_lmx_comments_left num_msx_scores_added num_life_list_machines profile_list_of_edited_locations profile_list_of_high_scores operator_name created_at profile_machine_scores_stats]
        includes.delete(:profile_list_of_high_scores) if params[:new_score_list_only]

        if params[:life_list]
          includes.delete(:profile_machine_scores_stats)
          includes.delete(:profile_list_of_high_scores)
          includes << :profile_life_list_stats
        end

        return_response(
          user,
          "profile_info",
          [],
          includes
        )
      rescue ActiveRecord::RecordNotFound
        return_response("Failed to find user", "errors")
      end

      api :GET, "/api/v1/users/life_list_info.json", "Query life list membership"
      param :by_machine_id, Integer, desc: "Machine ID to query", required: false
      param :by_user_id, Integer, desc: "User ID to query", required: false
      description "When no params are provided, returns all machines on at least one life list, sorted by count descending."
      formats [ "json" ]
      def life_list_info
        machine_except = %i[is_active created_at updated_at ipdb_id opdb_img opdb_img_height opdb_img_width machine_type machine_display ic_eligible]

        if params[:by_machine_id].present? && params[:by_user_id].present?
          in_list = UserMachineXref.exists?(user_id: params[:by_user_id], machine_id: params[:by_machine_id])
          has_scores = MachineScoreXref.where(user_id: params[:by_user_id], machine_id: params[:by_machine_id]).exists?
          return_response({ in_list: in_list, has_scores: has_scores }, "life_list_info")
        elsif params[:by_machine_id].present?
          machine = Machine.find(params[:by_machine_id])
          count = UserMachineXref.where(machine_id: params[:by_machine_id]).count
          render json: { life_list_info: { count: count, machine: machine.as_json(except: machine_except) } }
        elsif params[:by_user_id].present?
          umxes = UserMachineXref.where(user_id: params[:by_user_id]).includes(:machine)
          return_response(umxes, "user_machine_xrefs", [ machine: { except: machine_except } ])
        else
          machine_counts = UserMachineXref.group(:machine_id).order("count_all DESC").count
          machines_by_id = Machine.where(id: machine_counts.keys).index_by(&:id)
          results = machine_counts.map { |machine_id, count| { count: count, machine: machines_by_id[machine_id]&.as_json(except: machine_except) } }
          render json: { life_list_info: results }
        end
      rescue ActiveRecord::RecordNotFound
        return_response("Failed to find machine", "errors")
      end

      api :POST, "/api/v1/users/:id/add_life_list_machine.json", "Add a machine to your life list"
      param :id, Integer, desc: "ID of user", required: true
      param :machine_id, Integer, desc: "ID of machine to add", required: true
      formats [ "json" ]
      def add_life_list_machine
        user = User.find(params[:id])
        machine = Machine.find(params[:machine_id])

        if user.authentication_token != params[:user_token]
          return_response("Unauthorized user update.", "errors")
          return
        end

        UserMachineXref.find_or_create_by(user: user, machine: machine)
        return_response("Successfully added to life list", "success")
      rescue ActiveRecord::RecordNotFound
        return_response("Unknown asset", "errors")
      end

      api :POST, "/api/v1/users/:id/remove_life_list_machine.json", "Remove a machine from your life list"
      param :id, Integer, desc: "ID of user", required: true
      param :machine_id, Integer, desc: "ID of machine to remove", required: true
      formats [ "json" ]
      def remove_life_list_machine
        user = User.find(params[:id])

        if user.authentication_token != params[:user_token]
          return_response("Unauthorized user update.", "errors")
          return
        end

        umx = UserMachineXref.find_by(user: user, machine_id: params[:machine_id])

        unless umx
          return_response("Machine not in life list", "errors")
          return
        end

        if MachineScoreXref.where(user: user, machine_id: params[:machine_id]).exists?
          return_response("Cannot remove a machine that has scores from your list", "errors")
          return
        end

        umx.destroy
        return_response("Successfully removed from life list", "success")
      rescue ActiveRecord::RecordNotFound
        return_response("Unknown asset", "errors")
      end

      api :DELETE, "/api/v1/users/:id", "Delete a user account"
      description "Permanently delete your user account"
      param :id, Integer, desc: "ID of user", required: true
      formats [ "json" ]
      def destroy
        user = User.find(params[:id])

        if user.authentication_token != params[:user_token]
          return_response("Unauthorized user update.", "errors")
          return
        end

        user.destroy
        return_response("User deleted.", "msg")
      rescue ActiveRecord::RecordNotFound
        return_response("Unknown user", "errors")
      end

      api :POST, "/api/v1/users/:id/update_email", "Update email address"
      description "Update email address for a user"
      param :id, Integer, desc: "ID of user", required: true
      param :email, String, desc: "New email address", required: true
      formats [ "json" ]
      def update_email
        user = User.find(params[:id])

        if user.authentication_token != params[:user_token]
          return_response("Unauthorized user update.", "errors")
          return
        end

        if params[:email].blank?
          return_response("Email can not be blank", "errors")
          return
        end

        if user.update(email: params[:email])
          return_response("Email updated.", "msg")
        else
          return_response(user.errors.full_messages.join(", "), "errors")
        end
      rescue ActiveRecord::RecordNotFound
        return_response("Unknown user", "errors")
      end

      api :POST, "/api/v1/users/:id/update_password", "Update password"
      description "Update password for a user"
      param :id, Integer, desc: "ID of user", required: true
      param :current_password, String, desc: "Current password", required: true
      param :password, String, desc: "New password", required: true
      param :password_confirmation, String, desc: "New password confirmation", required: true
      formats [ "json" ]
      def update_password
        user = User.find(params[:id])

        if user.authentication_token != params[:user_token]
          return_response("Unauthorized user update.", "errors")
          return
        end

        if user.update_with_password(
          current_password: params[:current_password],
          password: params[:password],
          password_confirmation: params[:password_confirmation]
        )
          return_response("Password updated.", "msg")
        else
          return_response(user.errors.full_messages.join(", "), "errors")
        end
      rescue ActiveRecord::RecordNotFound
        return_response("Unknown user", "errors")
      end

      api :POST, "/api/v1/users/:id/update_user_flag", "Set a flag icon for your user"
      param :id, Integer, desc: "ID of user", required: true
      param :flag, String, desc: "ISO code for flag", required: false
      formats [ "json" ]
      def update_user_flag
        user = User.find(params[:id])

        if user.authentication_token != params[:user_token]
          return_response("Unauthorized user update.", "errors")
          return
        end

        user.flag = params[:flag]
        if user.save
          return_response(user, "user", [], %i[flag])
        else
          return_response("Unknown ISO code", "errors")
        end
      rescue ActiveRecord::RecordNotFound
        return_response("Unknown asset", "errors")
      end
    end
  end
end
