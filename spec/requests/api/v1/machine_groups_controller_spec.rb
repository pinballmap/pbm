require 'spec_helper'

describe Api::V1::MachineGroupsController, type: :request do
  describe '#index' do
    before(:each) do
      FactoryBot.create(:machine_group, id: 66, name: 'Cleo Group')
      FactoryBot.create(:machine_group, id: 67, name: 'Bawb Group')
    end

    it 'returns all machine groups in the database' do
      get '/api/v1/machine_groups.json'

      expect(response.body).to include('Cleo Group')
      expect(response.body).to include('Bawb Group')
    end
  end
end
