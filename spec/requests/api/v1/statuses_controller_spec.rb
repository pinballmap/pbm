require 'spec_helper'

describe Api::V1::StatusesController, type: :request do
  describe '#index' do
    before(:each) do
      FactoryBot.create(:status, status_type: 'regions', updated_at: Time.current - 1.day)
      FactoryBot.create(:status, status_type: 'machines', updated_at: Time.current - 1.day)
      FactoryBot.create(:status, status_type: 'operators', updated_at: Time.current - 1.day)
      FactoryBot.create(:status, status_type: 'location_types', updated_at: Time.current - 1.day)
    end

    it 'handles status displaying' do
      FactoryBot.create(:region, name: 'portland')
      FactoryBot.create(:machine, name: 'Attack From Cleo')
      FactoryBot.create(:operator, name: 'Sassy Moves Today')
      FactoryBot.create(:location_type, name: 'Broom Closet')

      get '/api/v1/statuses.json'
      expect(response).to be_successful

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      status_type = parsed_body['statuses']
      expect(status_type.size).to eq(4)

      about_now = Time.current.to_s.first(10)

      expect(status_type[0]['updated_at']).to start_with(about_now)
      expect(status_type[1]['updated_at']).to start_with(about_now)
      expect(status_type[2]['updated_at']).to start_with(about_now)
      expect(status_type[3]['updated_at']).to start_with(about_now)
    end
  end
end
