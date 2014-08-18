require 'spec_helper'

describe Api::V1::LocationsController, :type => :request do
  before(:each) do
    @portland = FactoryGirl.create(:region, :name => 'portland')
    @la = FactoryGirl.create(:region, :name => 'la')
    FactoryGirl.create(:user, :region => @portland, :email => 'portland@admin.com', :is_super_admin => 1)
    FactoryGirl.create(:user, :region => @la, :email => 'la@admin.com')
  end

  describe '#index' do
    it 'sends back additional, non-db fields' do
      FactoryGirl.create(:user, :region => @portland, :email => 'not@primary.com')
      FactoryGirl.create(:user, :region => @portland, :email => 'is@primary.com', :is_primary_email_contact => 1)

      get '/api/v1/regions.json'
      expect(response).to be_success

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      regions = parsed_body['regions']
      expect(regions.size).to eq(2)

      expect(regions[0]['name']).to eq('portland')
      expect(regions[0]['primary_email_contact']).to eq('is@primary.com')
      expect(regions[0]['all_admin_email_addresses']).to eq(["portland@admin.com", "not@primary.com", "is@primary.com"])

      expect(regions[1]['name']).to eq('la')
      expect(regions[1]['primary_email_contact']).to eq('la@admin.com')
      expect(regions[1]['all_admin_email_addresses']).to eq(["la@admin.com"])
    end
  end

  describe '#suggest' do
    it 'errors when required fields are not sent' do
      expect(Pony).to_not receive(:mail)
      post '/api/v1/regions/suggest.json'
      expect(response).to be_success

      expect(JSON.parse(response.body)['errors']).to eq('Your name, email address, and name of the region you want added are required fields.')

      expect(Pony).to_not receive(:mail)
      post '/api/v1/regions/suggest.json', name: 'foo'
      expect(response).to be_success

      expect(JSON.parse(response.body)['errors']).to eq('Your name, email address, and name of the region you want added are required fields.')

      expect(Pony).to_not receive(:mail)
      post '/api/v1/regions/suggest.json', name: 'foo', email: 'bar'
      expect(response).to be_success

      expect(JSON.parse(response.body)['errors']).to eq('Your name, email address, and name of the region you want added are required fields.')

      expect(Pony).to_not receive(:mail)
      post '/api/v1/regions/suggest.json', name: 'foo', region_name: 'bar'
      expect(response).to be_success

      expect(JSON.parse(response.body)['errors']).to eq('Your name, email address, and name of the region you want added are required fields.')
    end

    it 'emails portland admins on new region submission' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          :to => ["portland@admin.com"],
          :from =>"admin@pinballmap.com",
          :subject => "PBM - New region suggestion",
          :body => <<HERE
Their Name: name\n
Their Email: email\n
Region Name: region name\n
Region Comments: region comments\n
HERE
        )
      end

      post '/api/v1/regions/suggest.json', name: 'name', email: 'email', region_name: 'region name', comments: 'region comments'
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
    end

    it 'emails region admins with incoming message' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          :to => ["la@admin.com"],
          :bcc => ["portland@admin.com"],
          :from =>"admin@pinballmap.com",
          :subject => "PBM - New message from la region",
          :body => <<HERE
Their Email: email\n
Message: message\n
HERE
        )
      end

      post '/api/v1/regions/contact.json', region_id: @la.id.to_s, email: 'email', message: 'message'
      expect(response).to be_success

      expect(JSON.parse(response.body)['msg']).to eq("Thanks for the message.")
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

      expect(JSON.parse(response.body)['errors']).to eq('OS, OS Version, Device Type, App Version, Email, and Message are all required.')

      expect(Pony).to_not receive(:mail)
      post '/api/v1/regions/app_comment.json', region_id: @la.id.to_s, os: 'os', os_version: 'os version', device_type: 'device type', app_version: 'app version', message: 'message'
      expect(response).to be_success

      expect(JSON.parse(response.body)['errors']).to eq('OS, OS Version, Device Type, App Version, Email, and Message are all required.')
    end

    it 'emails app support address with feedback' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          :to => "pinballmap@outlook.com",
          :bcc => ["portland@admin.com"],
          :from =>"admin@pinballmap.com",
          :subject => "PBM - App feedback",
          :body => <<HERE
OS: os\n
OS Version: os version\n
Device Type: device type\n
App Version: app version\n
Region: la\n
Their Email: email\n
Message: message\n
HERE
        )
      end

      post '/api/v1/regions/app_comment.json', region_id: @la.id.to_s, os: 'os', os_version: 'os version', device_type: 'device type', app_version: 'app version', email: 'email', message: 'message'
      expect(response).to be_success

      expect(JSON.parse(response.body)['msg']).to eq("Thanks for the message.")
    end
  end
end
