require 'spec_helper'

describe Api::V1::MachinesController, type: :request do

  describe '#index' do
    before(:each) do
      FactoryGirl.create(:machine, name: 'Cleo')
      FactoryGirl.create(:machine, name: 'Bawb')
    end

    it 'returns all machines in the database' do
      get '/api/v1/machines.json'

      expect(response.body).to include('Cleo')
      expect(response.body).to include('Bawb')
    end
  end

  describe '#create' do
    before(:each) do
      @region = FactoryGirl.create(:region, name: 'Portland')
      @location = FactoryGirl.create(:location, name: 'Ground Kontrol')

      FactoryGirl.create(:machine, name: 'Cleo')
    end

    it 'errors with missing location_id' do
      post '/api/v1/machines.json?machine_name=Bawb;location_id='
      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('Failed to find location')
    end

    it 'handles creation by machine name.. machine exists with same name.. case insensitive' do
      post '/api/v1/machines.json?machine_name=Cleo;location_id=' + @location.id.to_s
      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('Machine already exists')

      post '/api/v1/machines.json?machine_name=cleo;location_id=' + @location.id.to_s
      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('Machine already exists')

      expect(Machine.all.size).to eq(1)
    end

    it 'handles creation by machine name.. machine exists with same name.. ignores preceeding and trailing whitespace' do
      post '/api/v1/machines.json?machine_name=%20Cleo%20;location_id=' + @location.id.to_s
      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('Machine already exists')

      expect(Machine.all.size).to eq(1)
    end

    it 'handles creation by machine name.. new machine name' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          body: "Bawb\nGround Kontrol\nportland\n(entered from 127.0.0.1 via )",
          subject: 'PBM - New machine name',
          to: [],
          from: 'admin@pinballmap.com'
        )
      end

      post '/api/v1/machines.json?machine_name=Bawb;location_id=' + @location.id.to_s
      expect(response).to be_success
      expect(response.status).to eq(201)
      expect(JSON.parse(response.body)['machine']['name']).to eq('Bawb')
    end
  end
end
