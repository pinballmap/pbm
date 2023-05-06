require 'spec_helper'

describe MachinesController, type: :controller do
  before(:each) do
    portland = FactoryBot.create(:region, name: 'portland')
    chicago = FactoryBot.create(:region)

    @machine1 = FactoryBot.create(:machine, id:7, name: 'Cleo')
    @machine2 = FactoryBot.create(:machine, id:77, name: 'Dredd')

    FactoryBot.create(:status, status_type: 'machines', updated_at: Time.now)
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

  describe '#autocomplete' do
    it 'should return a full list of all the machines' do
      get :autocomplete, format: :json, params: {}

      expect(response.body).to include('Cleo')
      expect(response.body).to include('Dredd')
    end

    it 'should honor the name filter' do
      get :autocomplete, format: :json, params: { term: 'red' }

      expect(response.body).not_to include('Cleo')
      expect(response.body).to include('Dredd')
    end

    it 'should honor the name filter' do
      get :autocomplete, format: :json, params: { term: 'abc' }

      expect(response.body).not_to include('Cleo')
      expect(response.body).not_to include('Dredd')
    end

    it 'should respect the cache' do
      get :autocomplete, format: :json, params: { term: 'abc' }

      expect(response.body).not_to include('Cleo')
      expect(response.body).not_to include('Dredd')

      get :autocomplete, format: :json, params: { term: 'cle' }

      expect(response.body).to include('Cleo')
      expect(response.body).not_to include('Dredd')

      machine3 = FactoryBot.create(:machine, id:777, name: 'Foo Fighters')

      get :autocomplete, format: :json, params: { term: 'fight' }

      expect(response.body).not_to include('Cleo')
      expect(response.body).not_to include('Dredd')
      expect(response.body).to include('Foo Fighters')

      @machine2.update(name: "lost")

      get :autocomplete, format: :json, params: { }

      expect(response.body).to include('Cleo')
      expect(response.body).to include('lost')
      expect(response.body).not_to include('Dredd')
      expect(response.body).to include('Foo Fighters')
    end
  end
end
