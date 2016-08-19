require 'spec_helper'

describe Api::V1::OperatorsController, type: :request do

  describe '#index' do
    before(:each) do
      @region = FactoryGirl.create(:region, name: 'portland')
    end

    it 'handles basic operator displaying' do
      FactoryGirl.create(:operator, region: @region, name: 'Sass')
      FactoryGirl.create(:operator, region: @region, name: 'Bawb')
      FactoryGirl.create(:operator, region: @region, name: 'Cleo')
      FactoryGirl.create(:operator, name: 'HOPE THIS DONT SHOW')

      get '/api/v1/region/portland/operators.json'
      expect(response).to be_success

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      operators = parsed_body['operators']
      expect(operators.size).to eq(3)

      expect(operators[0]['name']).to eq('Bawb')
      expect(operators[1]['name']).to eq('Cleo')
      expect(operators[2]['name']).to eq('Sass')
    end
  end

  describe '#show' do
    it 'sends back operator metadata' do
      operator = FactoryGirl.create(:operator, region: @region, name: 'Sass')

      get "/api/v1/operators/#{operator.id}.json"
      expect(response).to be_success
      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      operator_json = parsed_body['operator']

      expect(operator_json['name']).to eq('Sass')
    end

    it 'throws an error if the region does not exist' do
      get '/api/v1/operators/-123.json'

      expect(JSON.parse(response.body)['errors']).to eq('Failed to find operator')
    end
  end
end
