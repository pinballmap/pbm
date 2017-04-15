require 'spec_helper'

describe Api::V1::EventsController, type: :request do
  describe '#index' do
    before(:each) do
      @region = FactoryGirl.create(:region, name: 'portland')
      @location = FactoryGirl.create(:location, region: @region, state: 'OR')
    end

    it 'handles basic event displaying' do
      FactoryGirl.create(:event, region: @region, location: @location, name: 'event 1', start_date: Date.today)
      FactoryGirl.create(:event, region: @region, location: @location, name: 'event 2', start_date: Date.today + 1)
      FactoryGirl.create(:event, region: @region, location: @location, name: 'event 3')

      get '/api/v1/region/portland/events.json'
      expect(response).to be_success

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      events = parsed_body['events']
      expect(events.size).to eq(3)

      expect(events[0]['name']).to eq('event 1')
      expect(events[1]['name']).to eq('event 2')
      expect(events[2]['name']).to eq('event 3')
    end

    it 'handles the sorted param appropriately' do
      FactoryGirl.create(:event, region: @region, location: @location, name: 'event 1', start_date: Date.today, end_date: Date.today)
      FactoryGirl.create(:event, region: @region, location: @location, category: 'Foo', name: 'event 2', start_date: Date.today, end_date: Date.today)
      FactoryGirl.create(:event, region: @region, location: @location, category: 'Foo', name: 'event 3', start_date: Date.today, end_date: Date.today)

      get '/api/v1/region/portland/events.json', sorted: 'true'
      expect(response).to be_success

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      events = parsed_body['events']
      expect(events.size).to eq(1)

      expect(events[0]['General'][0]['name']).to eq('event 1')
      expect(events[0]['Foo'][0]['name']).to eq('event 2')
      expect(events[0]['Foo'][1]['name']).to eq('event 3')
    end

    it 'does not display events that are a week older than their end date' do
      FactoryGirl.create(:event, region: @region, location: @location, name: 'event 1', start_date: Date.today, end_date: Date.today)
      FactoryGirl.create(:event, region: @region, location: @location, name: 'event 2', start_date: Date.today - 8, end_date: Date.today - 8)

      get '/api/v1/region/portland/events.json'
      expect(response).to be_success

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      events = parsed_body['events']
      expect(events.size).to eq(1)

      expect(events[0]['name']).to eq('event 1')
    end

    it 'does not display events that are a week older than start date if there is no end date' do
      FactoryGirl.create(:event, region: @region, location: @location, name: 'event 1', start_date: Date.today)
      FactoryGirl.create(:event, region: @region, location: @location, name: 'event 2', start_date: Date.today - 8)

      get '/api/v1/region/portland/events.json'
      expect(response).to be_success

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      events = parsed_body['events']
      expect(events.size).to eq(1)

      expect(events[0]['name']).to eq('event 1')
    end

    it 'does displays events with no start and end date' do
      FactoryGirl.create(:event, region: @region, location: @location, name: 'event 1', start_date: nil, end_date: nil)
      FactoryGirl.create(:event, region: @region, location: @location, name: 'event 2', start_date: nil, end_date: nil)

      get '/api/v1/region/portland/events.json'
      expect(response).to be_success

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      events = parsed_body['events']
      expect(events.size).to eq(2)

      expect(events[0]['name']).to eq('event 2')
      expect(events[1]['name']).to eq('event 1')
    end
  end
end
