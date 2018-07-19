require 'spec_helper'

describe Api::V1::RegionsController, type: :request do
  before(:each) do
    @portland = FactoryBot.create(:region, id: 555, name: 'portland', motd: 'foo', full_name: 'Portland', lat: 12, lon: 13)
    @la = FactoryBot.create(:region, name: 'la', full_name: 'Los Angeles')

    FactoryBot.create(:user, region: @portland, email: 'portland@admin.com', is_super_admin: 1)
    FactoryBot.create(:user, region: @la, email: 'la@admin.com')
    @user = FactoryBot.create(:user, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw')
  end

  describe '#location_and_machine_counts' do
    before(:each) do
      @pdx_location = FactoryBot.create(:location, region: @portland)
      @pdx_location_two = FactoryBot.create(:location, region: @portland)
      @la_location = FactoryBot.create(:location, region: @la)
      @machine = FactoryBot.create(:machine)
      @machine_two = FactoryBot.create(:machine)

      FactoryBot.create(:location_machine_xref, machine_id: @machine.id, location_id: @pdx_location.id)
      FactoryBot.create(:location_machine_xref, machine_id: @machine_two.id, location_id: @pdx_location.id)
      FactoryBot.create(:location_machine_xref, machine_id: @machine.id, location_id: @pdx_location_two.id)
      FactoryBot.create(:location_machine_xref, machine_id: @machine.id, location_id: @la_location.id)
    end

    it 'tells you how many total locations and machines are tracked on pbm' do
      get '/api/v1/regions/location_and_machine_counts.json'

      expect(response).to be_successful
      parsed_body = JSON.parse(response.body)

      expect(parsed_body['num_locations']).to eq(3)
      expect(parsed_body['num_lmxes']).to eq(4)
    end

    it 'tells you how many total locations and machines are in a specific region' do
      get '/api/v1/regions/location_and_machine_counts.json', params: { region_name: @portland.name }

      expect(response).to be_successful
      parsed_body = JSON.parse(response.body)

      expect(parsed_body['num_locations']).to eq(2)
      expect(parsed_body['num_lmxes']).to eq(3)
    end

    it 'throws an error if name does not correspond to a region' do
      get '/api/v1/regions/location_and_machine_counts.json', params: { region_name: 'foo' }

      expect(JSON.parse(response.body)['errors']).to eq('This is not a valid region.')
    end
  end

  describe '#does_region_exist' do
    it 'tells you if name is a valid region' do
      FactoryBot.create(:region, id: 6, name: 'clark', motd: 'mine', lat: 12.0, lon: 13.0, full_name: 'Clarky')

      get '/api/v1/regions/does_region_exist.json', params: { name: 'clark' }
      expect(response).to be_successful
      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      region = parsed_body['region']

      expect(region['id']).to eq(6)
      expect(region['name']).to eq('clark')
      expect(region['motd']).to eq('mine')
      expect(region['lat']).to eq('12.0')
      expect(region['lon']).to eq('13.0')
      expect(region['full_name']).to eq('Clarky')
    end

    it 'throws an error if name does not correspond to a region' do
      get '/api/v1/regions/does_region_exist.json', params: { name: 'foo' }

      expect(JSON.parse(response.body)['errors']).to eq('This is not a valid region.')
    end
  end

  describe '#closest_by_lat_lon' do
    it 'sends back closest region' do
      FactoryBot.create(:region, name: 'not portland', lat: 122.0, lon: 13.0)

      get '/api/v1/regions/closest_by_lat_lon.json', params: { lat: 12.1, lon: 13.0 }
      expect(response).to be_successful
      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      region = parsed_body['region']

      expect(region['id']).to eq(555)
      expect(region['name']).to eq('portland')
      expect(region['motd']).to eq('foo')
      expect(region['lat']).to eq('12.0')
      expect(region['lon']).to eq('13.0')
      expect(region['full_name']).to eq('Portland')
    end

    it 'throws an error if no regions are within 250 miles' do
      get '/api/v1/regions/closest_by_lat_lon.json', params: { lat: 120.0, lon: 13.0 }

      expect(JSON.parse(response.body)['errors']).to eq('No regions within 250 miles.')
    end
  end

  describe '#show' do
    it 'sends back region metadata' do
      get "/api/v1/regions/#{@portland.id}.json"
      expect(response).to be_successful
      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      region = parsed_body['region']

      expect(region['name']).to eq('portland')
      expect(region['motd']).to eq('foo')
      expect(region['lat']).to eq('12.0')
      expect(region['lon']).to eq('13.0')
      expect(region['full_name']).to eq('Portland')
    end

    it 'throws an error if the region does not exist' do
      get '/api/v1/regions/-123.json'

      expect(JSON.parse(response.body)['errors']).to eq('Failed to find region')
    end
  end

  describe '#index' do
    it 'sends back additional, non-db fields' do
      FactoryBot.create(:user, region: @portland, email: 'not@primary.com')
      FactoryBot.create(:user, region: @portland, email: 'is@primary.com', is_primary_email_contact: 1)

      get '/api/v1/regions.json'
      expect(response).to be_successful

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      regions = parsed_body['regions']
      expect(regions.size).to eq(2)

      expect(regions[0]['name']).to eq('portland')
      expect(regions[0]['primary_email_contact']).to eq('is@primary.com')
      expect(regions[0]['all_admin_email_addresses']).to eq(['is@primary.com', 'not@primary.com', 'portland@admin.com'])

      expect(regions[1]['name']).to eq('la')
      expect(regions[1]['primary_email_contact']).to eq('la@admin.com')
      expect(regions[1]['all_admin_email_addresses']).to eq(['la@admin.com'])
    end
  end

  describe '#suggest' do
    it 'errors when required fields are not sent' do
      expect(Pony).to_not receive(:mail)
      post '/api/v1/regions/suggest.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('The name of the region you want added is a required field.')
    end

    it 'errors when not authed' do
      expect(Pony).to_not receive(:mail)
      post '/api/v1/regions/suggest.json', params: { region_name: 'region name', comments: 'region comments' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq(Api::V1::RegionsController::AUTH_REQUIRED_MSG)
    end

    it 'emails portland admins on new region submission' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          to: ['portland@admin.com'],
          from: 'admin@pinballmap.com',
          subject: 'PBM - New region suggestion',
          body: <<HERE
Their Name: ssw\n
Their Email: foo@bar.com\n
Region Name: region name\n
Region Comments: region comments\n
(entered from 127.0.0.1 via cleOS)\n
HERE
        )
      end

      post '/api/v1/regions/suggest.json', params: { region_name: 'region name', comments: 'region comments', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }, headers: { HTTP_USER_AGENT: 'cleOS' }
      expect(response).to be_successful

      expect(JSON.parse(response.body)['msg']).to eq("Thanks for suggesting that region. We'll be in touch.")
    end
  end

  describe '#contact' do
    it 'throws an error if the region does not exist' do
      post '/api/v1/regions/contact.json', params: { region_id: -1, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(JSON.parse(response.body)['errors']).to eq('Failed to find region')
    end

    it 'throws an error when not authed' do
      post '/api/v1/regions/contact.json', params: { region_id: @la.id.to_s, email: 'email', message: 'message', name: 'name' }

      expect(JSON.parse(response.body)['errors']).to eq(Api::V1::RegionsController::AUTH_REQUIRED_MSG)
    end

    it 'errors when required fields are not sent' do
      expect(Pony).to_not receive(:mail)
      post '/api/v1/regions/contact.json', params: { region_id: @la.id.to_s, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('A message is required.')

      expect(Pony).to_not receive(:mail)
      post '/api/v1/regions/contact.json', params: { region_id: @la.id.to_s, message: '', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('A message is required.')
    end

    it 'emails region admins with incoming message' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          to: ['la@admin.com'],
          cc: ['portland@admin.com'],
          from: 'admin@pinballmap.com',
          subject: 'PBM - Message from the Los Angeles region',
          body: <<HERE
Their Name: name\n
Their Email: email\n
Message: message\n
Username: ssw\n
Site Email: foo@bar.com\n
(entered from 127.0.0.1 via cleOS)\n
HERE
        )
      end

      post '/api/v1/regions/contact.json', params: { region_id: @la.id.to_s, email: 'email', message: 'message', name: 'name', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }, headers: { HTTP_USER_AGENT: 'cleOS' }
      expect(response).to be_successful

      expect(JSON.parse(response.body)['msg']).to eq('Thanks for the message.')
      expect(UserSubmission.all.count).to eq(1)
      expect(UserSubmission.first.submission_type).to eq(UserSubmission::CONTACT_US_TYPE)
    end

    it 'emails region admins with incoming message - authed' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          to: ['la@admin.com'],
          cc: ['portland@admin.com'],
          from: 'admin@pinballmap.com',
          subject: 'PBM - Message from the Los Angeles region',
          body: <<HERE
Their Name: name\n
Their Email: email\n
Message: message\n
Username: ssw\n
Site Email: foo@bar.com\n
(entered from 127.0.0.1 via cleOS)\n
HERE
        )
      end

      post '/api/v1/regions/contact.json', params: { region_id: @la.id.to_s, email: 'email', message: 'message', name: 'name', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }, headers: { HTTP_USER_AGENT: 'cleOS' }
      expect(response).to be_successful

      expect(JSON.parse(response.body)['msg']).to eq('Thanks for the message.')
      expect(UserSubmission.all.count).to eq(1)
      expect(UserSubmission.first.submission_type).to eq(UserSubmission::CONTACT_US_TYPE)
      expect(UserSubmission.first.user_id).to eq(@user.id)
    end

    it 'emails region admins with incoming message - notifies if sent from staging server' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          subject: '(STAGING) PBM - Message from the Los Angeles region'
        )
      end

      host! 'pinballmapstaging.herokuapp.com'

      post '/api/v1/regions/contact.json', params: { region_id: @la.id.to_s, email: 'email', message: 'message', name: 'name', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
    end
  end

  describe '#app_comment' do
    it 'throws an error if the region does not exist' do
      post '/api/v1/regions/app_comment.json', params: { region_id: -1, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(JSON.parse(response.body)['errors']).to eq('Failed to find region')
    end

    it 'throws an error if not authed' do
      post '/api/v1/regions/app_comment.json', params: { region_id: @la.id.to_s, os: 'os', os_version: 'os version', device_type: 'device type', app_version: 'app version', email: 'email', message: 'foo' }

      expect(JSON.parse(response.body)['errors']).to eq(Api::V1::RegionsController::AUTH_REQUIRED_MSG)
    end

    it 'errors when required fields are not sent' do
      expect(Pony).to_not receive(:mail)
      post '/api/v1/regions/app_comment.json', params: { region_id: @la.id.to_s, os: 'os', os_version: 'os version', device_type: 'device type', app_version: 'app version', email: 'email', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('region_id, os, os_version, device_type, app_version, email, message are all required.')

      expect(Pony).to_not receive(:mail)
      post '/api/v1/regions/app_comment.json', params: { region_id: @la.id.to_s, os: 'os', os_version: 'os version', device_type: 'device type', app_version: 'app version', message: 'message', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('region_id, os, os_version, device_type, app_version, email, message are all required.')

      expect(Pony).to_not receive(:mail)
      post '/api/v1/regions/app_comment.json', params: { region_id: @la.id.to_s, os: 'os', os_version: 'os version', device_type: 'device type', app_version: 'app version', message: 'message', email: '', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('region_id, os, os_version, device_type, app_version, email, message are all required.')
    end

    it 'emails app support address with feedback' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          to: 'pinballmap@fastmail.com',
          cc: ['portland@admin.com'],
          from: 'admin@pinballmap.com',
          subject: 'PBM - App feedback',
          body: <<HERE
OS: os\n
OS Version: os version\n
Device Type: device type\n
App Version: app version\n
Region: la\n
Their Name: name\n
Their Email: email\n
Message: message\n
HERE
        )
      end

      post '/api/v1/regions/app_comment.json', params: { region_id: @la.id.to_s, os: 'os', os_version: 'os version', device_type: 'device type', app_version: 'app version', email: 'email', message: 'message', name: 'name', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful

      expect(JSON.parse(response.body)['msg']).to eq('Thanks for the message.')
    end

    it 'emails app support address with feedback - notifies if origin is staging server' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          subject: '(STAGING) PBM - App feedback'
        )
      end

      host! 'pinballmapstaging.herokuapp.com'

      post '/api/v1/regions/app_comment.json', params: { region_id: @la.id.to_s, os: 'os', os_version: 'os version', device_type: 'device type', app_version: 'app version', email: 'email', message: 'message', name: 'name', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
    end
  end
end
