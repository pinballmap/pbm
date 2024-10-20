require 'spec_helper'

describe Api::V1::MachinesController, type: :request do
  describe '#index' do
    before(:each) do
      FactoryBot.create(:machine, id: 66, name: 'Cleo', manufacturer: 'Stern', machine_group_id: 1)
      FactoryBot.create(:machine, id: 67, name: 'Bawb', manufacturer: 'Williams', machine_group_id: 2)
    end

    it 'returns all machines in the database' do
      get '/api/v1/machines.json'

      expect(response.body).to include('Cleo')
      expect(response.body).to include('Bawb')
    end

    it 'respects manufacturer param' do
      get '/api/v1/machines.json?manufacturer=Stern'

      expect(response.body).to include('Cleo')
      expect(response.body).to_not include('Bawb')
    end

    it 'respects machine_group+id param' do
      get '/api/v1/machines.json?machine_group_id=1'

      expect(response.body).to include('Cleo')
      expect(response.body).to_not include('Bawb')
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
end
