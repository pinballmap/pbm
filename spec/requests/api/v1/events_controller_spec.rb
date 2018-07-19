require 'spec_helper'

describe Api::V1::EventsController, type: :request do
  describe '#index' do
    before(:each) do
      @region = FactoryBot.create(:region, name: 'portland')
      @location = FactoryBot.create(:location, region: @region, state: 'OR')
    end

    it 'handles basic event displaying' do
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 1', start_date: Date.today)
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 2', start_date: Date.today + 1)
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 3')

      get '/api/v1/region/portland/events.json'
      expect(response).to be_successful

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      events = parsed_body['events']
      expect(events.size).to eq(3)

      expect(events[0]['name']).to eq('event 1')
      expect(events[1]['name']).to eq('event 2')
      expect(events[2]['name']).to eq('event 3')
    end

    it 'handles the sorted param appropriately' do
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 1', start_date: Date.today, end_date: Date.today)
      FactoryBot.create(:event, region: @region, location: @location, category: 'Foo', name: 'event 2', start_date: Date.today, end_date: Date.today)
      FactoryBot.create(:event, region: @region, location: @location, category: 'Foo', name: 'event 3', start_date: Date.today, end_date: Date.today)

      get '/api/v1/region/portland/events.json', params: { sorted: 'true' }
      expect(response).to be_successful

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      events = parsed_body['events']
      expect(events.size).to eq(1)

      expect(events[0]['General'][0]['name']).to eq('event 1')
      expect(events[0]['Foo'][0]['name']).to eq('event 2')
      expect(events[0]['Foo'][1]['name']).to eq('event 3')
    end

    it 'does not display events that are a week older than their end date' do
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 1', start_date: Date.today, end_date: Date.today)
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 2', start_date: Date.today - 8, end_date: Date.today - 8)

      get '/api/v1/region/portland/events.json'
      expect(response).to be_successful

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      events = parsed_body['events']
      expect(events.size).to eq(1)

      expect(events[0]['name']).to eq('event 1')
    end

    it 'does not display events that are a week older than start date if there is no end date' do
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 1', start_date: Date.today)
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 2', start_date: Date.today - 8)

      get '/api/v1/region/portland/events.json'
      expect(response).to be_successful

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      events = parsed_body['events']
      expect(events.size).to eq(1)

      expect(events[0]['name']).to eq('event 1')
    end

    it 'does displays events with no start and end date' do
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 1', start_date: nil, end_date: nil)
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 2', start_date: nil, end_date: nil)

      get '/api/v1/region/portland/events.json'
      expect(response).to be_successful

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      events = parsed_body['events']
      expect(events.size).to eq(2)

      expect(events[0]['name']).to eq('event 2')
      expect(events[1]['name']).to eq('event 1')
    end
  end
end
