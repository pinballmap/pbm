module Api
  module V1
    class RegionsController < InheritedResources::Base
      skip_before_action :verify_authenticity_token

      before_action :allow_cors
      respond_to :json

      MAX_MILES_TO_SEARCH_FOR_CLOSEST_REGION = 250

      api :GET, '/api/v1/regions/location_and_machine_counts.json', 'Get location and machine counts'
      description 'Get location and machine counts'
      param :region_name, String, desc: 'region_name to limit counts to', required: false
      formats ['json']
      def location_and_machine_counts
        if params[:region_name]
          region = Region.where(['lower(name) = ?', params[:region_name].downcase]).first

          if region
            return_response({ num_locations: region.locations.count, num_lmxes: region.location_machine_xrefs.count }, nil)
          else
            return_response('This is not a valid region.', 'errors')
          end
        else
          return_response({ num_locations: Location.count, num_lmxes: LocationMachineXref.count }, nil)
        end
      end

      api :GET, '/api/v1/regions/does_region_exist.json', 'Find if name corresponds to a known region'
      description 'Find if name corresponds to a known region'
      param :name, String, desc: 'name of region', required: true
      formats ['json']
      def does_region_exist
        region = Region.find_by(name: params[:name])

        if region
          return_response(region, 'region', [], [:id])
        else
          return_response('This is not a valid region.', 'errors')
        end
      end

      api :GET, '/api/v1/regions/closest_by_lat_lon.json', 'Find closest region based on lat/lon'
      description 'Find closest region based on lat/lon'
      param :lat, String, desc: 'Lat', required: true
      param :lon, String, desc: 'Lon', required: true
      formats ['json']
      def closest_by_lat_lon
        closest_region = Region.near([params[:lat], params[:lon]], MAX_MILES_TO_SEARCH_FOR_CLOSEST_REGION).first

        if closest_region
          return_response(closest_region, 'region', [], [:id])
        else
          return_response("No regions within #{MAX_MILES_TO_SEARCH_FOR_CLOSEST_REGION} miles.", 'errors')
        end
      end

      api :GET, '/api/v1/regions.json', 'Fetch all regions'
      description 'Fetch data about all regions'
      def index
        regions = Region.includes(:users).all

        return_response(regions, 'regions', [], %i[primary_email_contact all_admin_email_addresses])
      end

      api :GET, '/api/v1/regions/:id.json', 'Fetch information for a single region'
      description 'Returns detail about a single region'
      param :id, String, desc: 'ID of the Region you want to see details about', required: true
      def show
        region = Region.find(params[:id])

        return_response(region, 'region', [], %i[primary_email_contact all_admin_email_addresses filtered_region_links n_high_rollers])
      rescue ActiveRecord::RecordNotFound
        return_response('Failed to find region', 'errors')
      end

      api :POST, '/api/v1/regions/suggest.json', 'Suggest a new region to add to the map'
      description "This doesn't actually create a new region, it just sends region information to pdx admins"
      param :region_name, String, desc: 'Region name', required: true
      param :comments, String, desc: 'Things we should know about this region', required: false
      formats ['json']
      def suggest
        user = current_user.nil? ? nil : current_user

        return return_response(AUTH_REQUIRED_MSG, 'errors') if user.nil?

        if params['region_name'].blank?
          return_response('The name of the region you want added is a required field.', 'errors')
          return
        end

        params['name'] = user.username
        params['email'] = user.email

        send_new_region_notification(params)
        return_response("Thanks for suggesting that region. We'll be in touch.", 'msg')
      end

      api :POST, '/api/v1/regions/contact.json', 'Contact regional administrator'
      description 'Send a message to the admins for a region'
      param :region_id, Integer, desc: 'ID of the region to send a message to', required: true
      param :message, String, desc: 'Message to admins', required: true
      param :name, String, desc: "Sender's name", required: false
      param :email, String, desc: "Sender's email address", required: false
      formats ['json']
      def contact
        user = current_user.nil? ? nil : current_user

        return return_response(AUTH_REQUIRED_MSG, 'errors') if user.nil?

        region = Region.find(params['region_id'])

        if params['message'].blank?
          return_response('A message is required.', 'errors')
          return
        end

        send_admin_notification(params, region, user)
        return_response('Thanks for the message.', 'msg')
      rescue ActiveRecord::RecordNotFound
        return_response('Failed to find region', 'errors')
      end

      api :POST, '/api/v1/regions/app_comment.json', 'Send comments about the app'
      description 'Send a message to app maintainers about the app'
      param :region_id, Integer, desc: 'ID of the region to send a message to', required: true
      param :os, String, desc: 'OS Type', required: true
      param :os_version, String, desc: 'OS Version', required: true
      param :device_type, String, desc: 'Device Type', required: true
      param :app_version, String, desc: 'App version', required: true
      param :email, String, desc: 'Your email address', required: true
      param :name, String, desc: 'Your name', required: false
      param :message, String, desc: 'Message to app maintainer', required: true
      formats ['json']
      def app_comment
        user = current_user.nil? ? nil : current_user

        return return_response(AUTH_REQUIRED_MSG, 'errors') if user.nil?

        region = Region.find(params['region_id'])

        required_fields = %w[region_id os os_version device_type app_version email message]

        required_fields.each do |field|
          if params[field].blank?
            return_response(required_fields.join(', ') + ' are all required.', 'errors')
            return
          end
        end

        send_app_comment(params, region)
        return_response('Thanks for the message.', 'msg')
      rescue ActiveRecord::RecordNotFound
        return_response('Failed to find region', 'errors')
      end
    end
  end
end
