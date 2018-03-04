require 'spec_helper'

describe RegionsController, type: :controller do
  before(:each) do
    @portland = FactoryBot.create(:region, name: 'portland')
  end

  describe '#show' do
    it 'finds region by id' do
      get :show, format: :json, params: { region: @portland.name, id: @portland.id }

      expect(response.body).to include('portland')
    end
  end
end
