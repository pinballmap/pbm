require 'spec_helper'

describe MachinesController, type: :controller do
  before(:each) do
    FactoryBot.create(:region, name: 'portland')
    FactoryBot.create(:machine, name: 'Cleo')
  end

  describe '#index' do
    it 'should return all records' do
      get :index, format: :json, params: {}

      expect(response.body).to include('Cleo')
      expect(response.body).to include('Dredd')
    end

    it 'should honor the by_name scope' do
      get :index, format: :json, params: { name: 'Cleo' }

      expect(response.body).to include('Cleo')
      expect(response.body).not_to include('Dredd')
    end
  end

      expect(response.body).to include('Cleo')
    end
  end
end
