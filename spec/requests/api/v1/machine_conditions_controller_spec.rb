require 'spec_helper'

describe Api::V1::MachineConditionsController, type: :request do
  before(:each) do
    @region = FactoryGirl.create(:region, name: 'portland')
    @location = FactoryGirl.create(:location, region: @region, name: 'Satchmo', state: 'OR', zip: '97203', lat: 42.18, lon: -71.18)
    @machine = FactoryGirl.create(:machine, name: 'Cleo')
  end

  describe '#destroy' do
    it 'removes an existing machine condition' do
      lmx = FactoryGirl.create(:location_machine_xref, location: @location, machine: @machine)
      mc = FactoryGirl.create(:machine_condition, location_machine_xref_id: lmx.id, comment: 'foo bar')

      delete "/api/v1/machine_conditions/#{mc.id}.json"
      expect(response).to be_success

      expect(response.body).to include('Successfully deleted machine condition #' + mc.id.to_s)
      expect(MachineCondition.all.size).to eq(0)
    end

    it 'errors if mc id does not exist' do
      lmx = FactoryGirl.create(:location_machine_xref, location: @location, machine: @machine)
      FactoryGirl.create(:machine_condition, location_machine_xref_id: lmx.id, comment: 'foo bar')

      delete '/api/v1/machine_conditions/-1.json'
      expect(response).to be_success

      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine condition')
      expect(MachineCondition.all.size).to eq(1)
    end
  end
end
