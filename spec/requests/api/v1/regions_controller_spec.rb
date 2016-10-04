require 'spec_helper'

describe Api::V1::LocationsController, type: :request do
  before(:each) do
    @portland = FactoryGirl.create(:region, id: 555, name: 'portland', motd: 'foo', full_name: 'Portland', lat: 12, lon: 13)
    @la = FactoryGirl.create(:region, name: 'la', full_name: 'Los Angeles')

    FactoryGirl.create(:user, region: @portland, email: 'portland@admin.com', is_super_admin: 1)
    FactoryGirl.create(:user, region: @la, email: 'la@admin.com')
    FactoryGirl.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw')
  end

  describe '#closest_by_lat_lon' do
    it 'sends back closest region' do
      FactoryGirl.create(:region, name: 'not portland', lat: 122.0, lon: 13.0)

      get '/api/v1/regions/closest_by_lat_lon.json', lat: 12.1, lon: 13.0
      expect(response).to be_success
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
      get '/api/v1/regions/closest_by_lat_lon.json', lat: 120.0, lon: 13.0

      expect(JSON.parse(response.body)['errors']).to eq('No regions within 250 miles.')
    end
  end

  describe '#show' do
    it 'sends back region metadata' do
      get "/api/v1/regions/#{@portland.id}.json"
      expect(response).to be_success
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
      FactoryGirl.create(:user, region: @portland, email: 'not@primary.com')
      FactoryGirl.create(:user, region: @portland, email: 'is@primary.com', is_primary_email_contact: 1)

      get '/api/v1/regions.json'
      expect(response).to be_success

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
      post '/api/v1/regions/suggest.json'
      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('The name of the region you want added is a required field.')
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
HERE
        )
      end

      post '/api/v1/regions/suggest.json', region_name: 'region name', comments: 'region comments', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a'
      expect(response).to be_success

      expect(JSON.parse(response.body)['msg']).to eq("Thanks for suggesting that region. We'll be in touch.")
    end
  end

  describe '#contact' do
    it 'throws an error if the region does not exist' do
      post '/api/v1/regions/contact.json', region_id: -1

      expect(JSON.parse(response.body)['errors']).to eq('Failed to find region')
    end

    it 'errors when required fields are not sent' do
      expect(Pony).to_not receive(:mail)
      post '/api/v1/regions/contact.json', region_id: @la.id.to_s
      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('A message is required.')

      expect(Pony).to_not receive(:mail)
      post '/api/v1/regions/contact.json', region_id: @la.id.to_s, message: ''
      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('A message is required.')
    end

    it 'emails region admins with incoming message' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          to: ['la@admin.com'],
          bcc: ['portland@admin.com'],
          from: 'admin@pinballmap.com',
          subject: 'PBM - Message from the Los Angeles region',
          body: <<HERE
Their Name: name\n
Their Email: email\n
Message: message\n\n
HERE
        )
      end

      post '/api/v1/regions/contact.json', region_id: @la.id.to_s, email: 'email', message: 'message', name: 'name'
      expect(response).to be_success

      expect(JSON.parse(response.body)['msg']).to eq('Thanks for the message.')
      expect(UserSubmission.all.count).to eq(1)
      expect(UserSubmission.first.submission_type).to eq(UserSubmission::CONTACT_US_TYPE)
    end

    it 'emails region admins with incoming message - authed' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          to: ['la@admin.com'],
          bcc: ['portland@admin.com'],
          from: 'admin@pinballmap.com',
          subject: 'PBM - Message from the Los Angeles region',
          body: <<HERE
Their Name: name\n
Their Email: email\n
Message: message\n
Username: ssw\n
Site Email: foo@bar.com
HERE
        )
      end

      post '/api/v1/regions/contact.json', region_id: @la.id.to_s, email: 'email', message: 'message', name: 'name', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a'
      expect(response).to be_success

      expect(JSON.parse(response.body)['msg']).to eq('Thanks for the message.')
      expect(UserSubmission.all.count).to eq(1)
      expect(UserSubmission.first.submission_type).to eq(UserSubmission::CONTACT_US_TYPE)
      expect(UserSubmission.first.user_id).to eq(111)
    end

    it 'emails region admins with incoming message - notifies if sent from staging server' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          subject: '(STAGING) PBM - Message from the Los Angeles region'
        )
      end

      post '/api/v1/regions/contact.json', { region_id: @la.id.to_s, email: 'email', message: 'message', name: 'name' }, HTTP_HOST: 'pinballmapstaging.herokuapp.com'
    end
  end

  describe '#app_comment' do
    it 'throws an error if the region does not exist' do
      post '/api/v1/regions/app_comment.json', region_id: -1

      expect(JSON.parse(response.body)['errors']).to eq('Failed to find region')
    end

    it 'errors when required fields are not sent' do
      expect(Pony).to_not receive(:mail)
      post '/api/v1/regions/app_comment.json', region_id: @la.id.to_s, os: 'os', os_version: 'os version', device_type: 'device type', app_version: 'app version', email: 'email'
      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('region_id, os, os_version, device_type, app_version, email, message are all required.')

      expect(Pony).to_not receive(:mail)
      post '/api/v1/regions/app_comment.json', region_id: @la.id.to_s, os: 'os', os_version: 'os version', device_type: 'device type', app_version: 'app version', message: 'message'
      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('region_id, os, os_version, device_type, app_version, email, message are all required.')

      expect(Pony).to_not receive(:mail)
      post '/api/v1/regions/app_comment.json', region_id: @la.id.to_s, os: 'os', os_version: 'os version', device_type: 'device type', app_version: 'app version', message: 'message', email: ''
      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('region_id, os, os_version, device_type, app_version, email, message are all required.')
    end

    it 'emails app support address with feedback' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          to: 'pinballmap@outlook.com',
          bcc: ['portland@admin.com'],
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

      post '/api/v1/regions/app_comment.json', region_id: @la.id.to_s, os: 'os', os_version: 'os version', device_type: 'device type', app_version: 'app version', email: 'email', message: 'message', name: 'name'
      expect(response).to be_success

      expect(JSON.parse(response.body)['msg']).to eq('Thanks for the message.')
    end

    it 'emails app support address with feedback - notifies if origin is staging server' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          subject: '(STAGING) PBM - App feedback'
        )
      end

      post '/api/v1/regions/app_comment.json', { region_id: @la.id.to_s, os: 'os', os_version: 'os version', device_type: 'device type', app_version: 'app version', email: 'email', message: 'message', name: 'name' }, HTTP_HOST: 'pinballmapstaging.herokuapp.com'
    end
  end
end
