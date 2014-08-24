module Api
  module V1
    class RegionsController < InheritedResources::Base
      before_filter :allow_cors
      respond_to :json

      api :GET, '/api/v1/regions.json', 'Fetch all regions'
      def index
        regions = Region.all

        return_response(regions, 'regions', [], [:primary_email_contact,:all_admin_email_addresses])
      end

      api :POST, '/api/v1/regions/suggest.json', 'Suggest a new region to add to the map'
      description "This doesn't actually create a new region, it just sends region information to pdx admins"
      param :name, String, :desc => "Region suggestor's name", :required => true
      param :email, String, :desc => "Region suggestor's email address", :required => true
      param :region_name, String, :desc => 'Region name', :required => true
      param :comments, String, :desc => 'Things we should know about this region', :required => false
      formats [ 'json' ]
      def suggest
        if (params['name'].blank? || params['email'].blank? || params['region_name'].blank?)
          return_response('Your name, email address, and name of the region you want added are required fields.', 'errors')
          return
        end

        send_new_region_notification(params)
        return_response("Thanks for suggesting that region. We'll be in touch.", 'msg')
      end

      api :POST, '/api/v1/regions/contact.json', 'Contact regional administrator'
      description "Send a message to the admins for a region"
      param :region_id, Integer, :desc => 'ID of the region to send a message to', :required => true
      param :message, String, :desc => "Message to admins", :required => true
      param :email, String, :desc => "Sender's email address", :required => false
      formats [ 'json' ]
      def contact
        region = Region.find(params['region_id'])

        if (params['message'].blank?)
          return_response('A message is required.', 'errors')
          return
        end

        send_admin_notification(params, region)
        return_response("Thanks for the message.", 'msg')

        rescue ActiveRecord::RecordNotFound
          return_response('Failed to find region', 'errors')
      end

      api :POST, '/api/v1/regions/app_comment.json', 'Send comments about the app'
      description "Send a message to app maintainers about the app"
      param :region_id, Integer, :desc => 'ID of the region to send a message to', :required => true
      param :os, String, :desc => "OS Type", :required => true
      param :os_version, String, :desc => "OS Version", :required => true
      param :device_type, String, :desc => "Device Type", :required => true
      param :app_version, String, :desc => "App version", :required => true
      param :email, String, :desc => "Your email address", :required => true
      param :message, String, :desc => "Message to app maintainer", :required => true
      formats [ 'json' ]
      def app_comment
        region = Region.find(params['region_id'])

        if (params['region_id'].blank? || params['os'].blank? || params['os_version'].blank? || params['device_type'].blank? || params['app_version'].blank? || params['email'].blank? || params['message'].blank?)
          return_response('OS, OS Version, Device Type, App Version, Email, and Message are all required.', 'errors')
          return
        end

        send_app_comment(params, region)
        return_response("Thanks for the message.", 'msg')

        rescue ActiveRecord::RecordNotFound
          return_response('Failed to find region', 'errors')
      end

    end
  end
end
