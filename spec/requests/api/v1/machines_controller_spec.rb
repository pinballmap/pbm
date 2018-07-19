require 'spec_helper'

describe Api::V1::MachinesController, type: :request do
  describe '#index' do
    before(:each) do
      FactoryBot.create(:machine, name: 'Cleo')
      FactoryBot.create(:machine, name: 'Bawb')
    end

    it 'returns all machines in the database' do
      get '/api/v1/machines.json'

      expect(response.body).to include('Cleo')
      expect(response.body).to include('Bawb')
    end

    it 'respects no_details param' do
      get '/api/v1/machines.json?no_details=1'

      expect(response.body).to include('Cleo')
      expect(response.body).to include('Bawb')

      expect(response.body.scan('is_active').size).to eq(0)
      expect(response.body.scan('created_at').size).to eq(0)
      expect(response.body.scan('updated_at').size).to eq(0)
      expect(response.body.scan('ipdb_link').size).to eq(0)
      expect(response.body.scan('ipdb_id').size).to eq(0)
      expect(response.body.scan('opdb_id').size).to eq(0)
      expect(response.body.scan('machine_group_id').size).to eq(0)
    end

    it 'respects region filter' do
      portland = FactoryBot.create(:region)
      location = FactoryBot.create(:location, region: portland)
      FactoryBot.create(:location_machine_xref, location: location, machine: FactoryBot.create(:machine, id: 7, name: 'Cleo'))

      chicago = FactoryBot.create(:region)
      another_location = FactoryBot.create(:location, region: chicago)
      FactoryBot.create(:location_machine_xref, location: another_location, machine: FactoryBot.create(:machine, id: 77, name: 'Bawb'))

      get "/api/v1/machines.json?region_id=#{portland.id}"

      expect(response.body).to include('Cleo')
      expect(response.body).not_to include('Bawb')
    end
  end

  describe '#create' do
    before(:each) do
      @region = FactoryBot.create(:region, name: 'Portland')
      @location = FactoryBot.create(:location, name: 'Ground Kontrol')

      FactoryBot.create(:machine, name: 'Cleo')
      FactoryBot.create(:user, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw')
    end

    it 'errors with missing location_id' do
      post '/api/v1/machines.json', params: { machine_name: 'Bawb', location_id: nil, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Failed to find location')
    end

    it 'errors when not authed' do
      post '/api/v1/machines.json', params: { machine_name: 'Auth Bawb', location_id: @location.id.to_s }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq(Api::V1::MachinesController::AUTH_REQUIRED_MSG)
    end

    it 'handles creation by machine name.. machine exists with same name.. case insensitive' do
      post '/api/v1/machines.json', params: { machine_name: 'Cleo', location_id: @location.id.to_s, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Machine already exists')

      post '/api/v1/machines.json', params: { machine_name: 'cleo', location_id: @location.id.to_s, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Machine already exists')

      expect(Machine.all.size).to eq(1)
    end

    it 'handles creation by machine name.. machine exists with same name.. ignores preceeding and trailing whitespace' do
      post '/api/v1/machines.json', params: { machine_name: ' Cleo ', location_id: @location.id.to_s, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Machine already exists')

      expect(Machine.all.size).to eq(1)
    end

    it 'handles creation by machine name.. new machine name' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          body: "Bawb\nGround Kontrol\nportland\n(entered from 127.0.0.1 via  by ssw (foo@bar.com))",
          subject: 'PBM - New machine name',
          to: [],
          from: 'admin@pinballmap.com'
        )
      end

      post '/api/v1/machines.json', params: { machine_name: 'Bawb', location_id: @location.id.to_s, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(response.status).to eq(201)
      expect(JSON.parse(response.body)['machine']['name']).to eq('Bawb')
    end

    it 'handles creation by machine name.. new machine name - authed' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          body: "Auth Bawb\nGround Kontrol\nportland\n(entered from 127.0.0.1 via  by ssw (foo@bar.com))",
          subject: 'PBM - New machine name',
          to: [],
          from: 'admin@pinballmap.com'
        )
      end

      post '/api/v1/machines.json', params: { machine_name: 'Auth Bawb', location_id: @location.id.to_s, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(response.status).to eq(201)
      expect(JSON.parse(response.body)['machine']['name']).to eq('Auth Bawb')
    end
  end
end
