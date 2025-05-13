module Api
  module V1
    class RegionsController < ApplicationController
      skip_before_action :verify_authenticity_token

      before_action :allow_cors

      MAX_MILES_TO_SEARCH_FOR_CLOSEST_REGION = 250

      api :GET, "/api/v1/regions/location_and_machine_counts.json", "Get location and machine counts"
      description "Get location and machine counts"
      param :region_name, String, desc: "region_name to limit counts to", required: false
      formats [ "json" ]
      def location_and_machine_counts
        if params[:region_name]
          region = Region.where([ "lower(name) = ?", params[:region_name].downcase ]).first

          if region
            return_response({ num_locations: region.locations.count, num_lmxes: region.location_machine_xrefs.count }, nil)
          else
            return_response("This is not a valid region.", "errors")
          end
        else
          return_response({ num_locations: Location.count, num_lmxes: LocationMachineXref.count }, nil)
        end
      end

      api :GET, "/api/v1/regions/does_region_exist.json", "Find if name corresponds to a known region"
      description "Find if name corresponds to a known region"
      param :name, String, desc: "name of region", required: true
      formats [ "json" ]
      def does_region_exist
        region = Region.find_by(name: params[:name])

        if region
          return_response(region, "region", [], [ :id ])
        else
          return_response("This is not a valid region.", "errors")
        end
      end

      api :GET, "/api/v1/regions/closest_by_lat_lon.json", "Find closest region based on lat/lon"
      description "Find closest region based on lat/lon"
      param :lat, String, desc: "Lat", required: true
      param :lon, String, desc: "Lon", required: true
      formats [ "json" ]
      def closest_by_lat_lon
        closest_region = Region.near([ params[:lat], params[:lon] ], MAX_MILES_TO_SEARCH_FOR_CLOSEST_REGION).first

        if closest_region
          return_response(closest_region, "region", [], [ :id ])
        else
          return_response("No regions within #{MAX_MILES_TO_SEARCH_FOR_CLOSEST_REGION} miles.", "errors")
        end
      end

      api :GET, "/api/v1/regions.json", "Fetch all regions"
      description "Fetch data about all regions"
      def index
        regions = Region.all
        except = %i[n_search_no default_search_type should_email_machine_removal should_auto_delete_empty_locations send_digest_comment_emails send_digest_removal_emails primary_email_contact all_admin_email_addresses created_at updated_at]

        return_response(regions, "regions", [], [], 200, except)
      end

      api :GET, "/api/v1/regions/:id.json", "Fetch information for a single region"
      description "Returns detail about a single region"
      param :id, String, desc: "ID of the Region you want to see details about", required: true
      def show
        region = Region.find(params[:id])
        except = %i[n_search_no default_search_type should_email_machine_removal should_auto_delete_empty_locations send_digest_comment_emails send_digest_removal_emails primary_email_contact all_admin_email_addresses filtered_region_links n_high_rollers]

        return_response(region, "region", [], [], 200, except)
      rescue ActiveRecord::RecordNotFound
        return_response("Failed to find region", "errors")
      end

      api :POST, "/api/v1/regions/contact.json", "Contact regional administrator"
      description "Send a message to the admins for a region"
      param :message, String, desc: "Message to admins", required: true
      param :region_id, Integer, desc: "ID of the region to send a message to", required: false
      param :lat, String, desc: "Latitude", required: false
      param :lon, String, desc: "Longitude", required: false
      param :name, String, desc: "Sender's name", required: false
      param :email, String, desc: "Sender's email address", required: false
      formats [ "json" ]
      def contact
        user = current_user.nil? ? nil : current_user

        region = nil
        if params[:region_id]
          region = Region.find(params["region_id"])
        else
          region = Region.near([ params[:lat], params[:lon] ], :effective_radius).first
        end

        if params["message"].blank? || (!user && params["email"].blank?)
          return_response("A message (and email if not logged in) is required.", "errors")
          return
        end

        send_admin_notification(params, region, user)
        return_response("Thanks for the message.", "msg")
      rescue ActiveRecord::RecordNotFound
        return_response("Failed to find region", "errors")
      end
    end
  end
end
