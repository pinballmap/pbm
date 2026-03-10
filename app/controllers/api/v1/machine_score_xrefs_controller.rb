module Api
  module V1
    class MachineScoreXrefsController < ApplicationController
      include ActionView::Helpers::NumberHelper
      skip_before_action :verify_authenticity_token

      before_action :allow_cors
      has_scope :region, :limit, :zone_id
      rate_limit to: 40, within: 5.minutes, only: :create

      api :GET, "/api/v1/region/:region/machine_score_xrefs.json", "Fetch all high scores for a region"
      param :region, String, desc: "Name of the Region you want to see scores for", required: true
      param :zone_id, Integer, desc: "ID of the zone you want to see scores for", required: false
      param :limit, Integer, desc: "Limit number of results returned", required: false
      formats [ "json" ]
      def index
        scores = apply_scopes(MachineScoreXref).includes(:user).order("id desc")
        return_response(scores, "machine_score_xrefs", [], %i[ username machine ])
      end

      api :GET, "/api/v1/machine_score_xrefs/:id.json", "View all high scores for a location's machine"
      param :id, Integer, desc: "The location machine ID (LMX ID), NOT the machine ID", required: true
      param :user_id, Integer, desc: "Limits to scores from a single user for this machine", required: false
      formats [ "json" ]
      def show
        lmx = LocationMachineXref.find(params[:id])

        msxes = MachineScoreXref.where(location_machine_xref_id: lmx.id).order("score desc")

        msxes = msxes.where(user_id: params[:user_id]) if params[:user_id].present?

        return_response(msxes, "machine_scores", [], [ :username ])
      rescue ActiveRecord::RecordNotFound
        return_response("Failed to find machine", "errors")
      end

      api :GET, "/api/v1/machine_score_xrefs/highest.json", "View highest high score for a machine"
      param :by_machine_id, Integer, desc: "Limit to the highest score for this machine ID", required: false
      param :by_user_id, Integer, desc: "Limit to highest score for a single user", required: false
      formats [ "json" ]
      def highest
        all_msxs = MachineScoreXref.all.where.not(machine_id: nil)

        all_msxs = all_msxs.where(user: params[:by_user_id]).includes(:user) if params[:by_user_id].present?

        all_msxs = all_msxs.where(machine_id: params[:by_machine_id]) if params[:by_machine_id].present?

        all_msxs = all_msxs
          .joins(:machine)
          .includes(:machine)
          .select("DISTINCT ON (machines.name, machine_id) machine_score_xrefs.*")
          .order("machines.name, machine_id, score DESC")

        return_response(all_msxs, "highest_scores", [ machine: { except: %i[is_active created_at updated_at ipdb_link ipdb_id opdb_img opdb_img_height opdb_img_width machine_type machine_display ic_eligible kineticist_url] } ], %i[ username ])
      rescue ActiveRecord::RecordNotFound
        return_response("Failed to find machine", "errors")
      end

      api :POST, "/api/v1/machine_score_xrefs.json", "Enter a new high score for a machine"
      param :location_machine_xref_id, Integer, desc: "Location machine identifier for high score", required: true
      param :score, String, desc: "A pinball machine high score", required: false
      formats [ "json" ]
      def create
        user = current_user.nil? ? nil : current_user

        return return_response(AUTH_REQUIRED_MSG, "errors") if user.nil?

        score = params[:score]

        if score.blank?
          return_response("Score can not be blank and must be a numeric value", "errors")
          return
        end

        score.gsub!(/[^0-9]/, "")

        if score.blank? || score.to_i.zero?
          return_response("Score can not be blank and must be a numeric value", "errors")
          return
        end

        lmx = LocationMachineXref.find(params[:location_machine_xref_id])

        msx = MachineScoreXref.new(location_machine_xref_id: lmx.id)

        machine_id = LocationMachineXref.where(id: params[:location_machine_xref_id]).pluck(:machine_id).first

        msx.score = score
        msx.user = user
        msx.machine_id = machine_id

        if msx.save
          msx.create_user_submission
          return_response(msx, "machine_score_xref", [], [ :username ], 201)
        else
          return_response(msx.errors.full_messages, "errors")
        end
      rescue ActiveRecord::RecordNotFound
        return_response("Failed to find machine", "errors")
      rescue RangeError
        return_response("Number is too large. Please enter a valid score.", "errors")
      end

      api :PUT, "/api/v1/machine_score_xrefs/:id.json", "Update a high score"
      param :id, Integer, desc: "ID of the high score you want to update", required: true
      param :score, String, desc: "Updated score", required: true
      formats [ "json" ]
      def update
        high_score = MachineScoreXref.find(params[:id])
        us = UserSubmission.find_by(machine_score_xref_id: high_score[:id])

        user = current_user.nil? ? nil : current_user
        return return_response(AUTH_REQUIRED_MSG, "errors") if user.nil?

        if high_score.user == user
          high_score.update({ score: params[:score] })

          us.high_score = params[:score]

          us.submission = "#{us.user_name} added a high score of #{number_with_precision(params[:score], precision: 0, delimiter: ',')} on #{us.machine_name} at #{us.location_name} in #{us.city_name}" if us.user_name.present? && us.machine_name.present? && us.location_name.present? && us.city_name.present?
          us.save

          return_response("Successfully updated high score", "high_score")
        else
          return_response("You can only update high scores that you own", "errors")
        end
      rescue ActiveRecord::RecordNotFound
        return_response("Failed to find high score", "errors")
      end

      api :DESTROY, "/api/v1/machine_score_xrefs/:id.json", "Destroy a single high score"
      param :id, String, desc: "ID of the high score you want to destroy", required: true
      def destroy
        high_score = MachineScoreXref.find(params[:id])
        us = UserSubmission.find_by(machine_score_xref_id: high_score[:id])

        user = current_user.nil? ? nil : current_user
        return return_response(AUTH_REQUIRED_MSG, "errors") if user.nil?

        if high_score.user == user
          high_score.destroy
          us.deleted_at = Time.now
          us.save
          return_response("Successfully removed high score", "high_score")
        else
          return_response("You can only delete high scores that you own", "errors")
        end
      rescue ActiveRecord::RecordNotFound
        return_response("Failed to find high score", "errors")
      end
    end
  end
end
