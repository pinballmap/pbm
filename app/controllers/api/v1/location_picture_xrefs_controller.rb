module Api
  module V1
    class LocationPictureXrefsController < ApplicationController
      skip_before_action :verify_authenticity_token

      before_action :allow_cors
      rate_limit to: 20, within: 2.minutes, only: :create

      api :GET, "/api/v1/location_picture_xrefs/:id.json", "Get info about a single lpx"
      param :id, Integer, desc: "LPX id", required: true
      formats [ "json" ]
      def show
        lpx = LocationPictureXref.includes(photo_attachment: :blob).find(params[:id])
        return return_response("No photo attached", "errors") unless lpx.photo.attached?

        url = if Rails.env.test?
          rails_representation_url(lpx.photo)
        else
          rails_representation_url(lpx.photo.variant(resize_to_limit: [ 1200, 1200 ]).processed)
        end

        return_response({ id: lpx.id, location_id: lpx.location_id, url: url }, "location_picture")
      rescue ActiveRecord::RecordNotFound
        return_response("Failed to find lpx", "errors")
      end

      api :POST, "/api/v1/location_picture_xrefs.json", "Add a picture for a location"
      param :location_id, Integer, desc: "Location ID to add picture to", required: true
      param :photo, File, desc: "The picture to add", required: true
      formats [ "json" ]
      def create
        return unless (user = require_api_user)

        location_id = params[:location_id].to_i
        return return_response("Failed to find location", "errors") if location_id.zero? || !Location.exists?(location_id)

        photo = params[:photo]
        return return_response("Missing photo to add", "errors") if photo.nil?

        lpx = LocationPictureXref.new(photo: photo, location_id: location_id, user_id: user.id)
        lpx.user = user

        if lpx.save
          lpx.create_user_submission
          return_response(lpx, "location_picture", [], [], 201)
        else
          return_response(lpx.errors.full_messages.join(", "), "errors", [], [], 422)
        end
      end

      api :DESTROY, "/api/v1/location_picture_xrefs/:id.json", "Remove a picture from a location"
      param :id, Integer, desc: "LPX id", required: true
      formats [ "json" ]
      def destroy
        return unless (user = require_api_user)

        lpx = LocationPictureXref.find(params[:id])
        lpx.create_remove_user_submission(user)
        lpx.destroy
        return_response("Successfully deleted lpx #{lpx.id}", "msg")
      rescue ActiveRecord::RecordNotFound
        return_response("Failed to find picture", "errors")
      end
    end
  end
end
