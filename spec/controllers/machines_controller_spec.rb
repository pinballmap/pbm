require 'spec_helper'

describe MachinesController, type: :controller do
  before(:each) do
    FactoryBot.create(:region, name: 'portland')
    FactoryBot.create(:machine, name: 'Cleo')
  end

  describe '#index' do
    it 'should honor the by_name scope' do
      get :index, format: :json, params: { region: 'portland' }

      expect(response.body).to include('Cleo')
    end
  end
end
