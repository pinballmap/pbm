require 'spec_helper'

describe Api::V1::LocationsController, type: :request do
  before(:each) do
    @region = FactoryGirl.create(:region, name: 'portland')
    @location = FactoryGirl.create(:location, region: @region, name: 'Satchmo', state: 'OR', zip: '97203', lat: 42.18, lon: -71.18)
    FactoryGirl.create(:user, email: 'foo@bar.com', region: @region)
    FactoryGirl.create(:user, email: 'super_admin@bar.com', region: nil, is_super_admin: 1)
  end

  describe '#suggest' do
    it 'errors when required fields are not sent' do
      expect(Pony).to_not receive(:mail)
      post '/api/v1/locations/suggest.json', region_id: @region.id.to_s
      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('Region, location name, and a list of machines are required')

      expect(Pony).to_not receive(:mail)
      post '/api/v1/locations/suggest.json', region_id: @region.id.to_s, location_machines: 'foo'
      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('Region, location name, and a list of machines are required')

      expect(Pony).to_not receive(:mail)
      post '/api/v1/locations/suggest.json', region_id: @region.id.to_s, location_name: 'baz'
      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('Region, location name, and a list of machines are required')

      expect(Pony).to_not receive(:mail)
      post '/api/v1/locations/suggest.json', region_id: @region.id.to_s, location_name: 'baz', location_machines: ''
      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('Region, location name, and a list of machines are required')
    end

    it 'errors when region is not available' do
      post '/api/v1/locations/suggest.json', region_id: -1, location_machines: 'foo', location_name: 'bar'
      expect(response).to be_success

      expect(JSON.parse(response.body)['errors']).to eq('Failed to find region')
    end

    it 'emails admins on new location submission' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          to: ['foo@bar.com'],
          bcc: ['super_admin@bar.com'],
          from: 'admin@pinballmap.com',
          subject: 'PBM - New location suggested for the portland pinball map',
          body: <<HERE
(A new pinball spot has been submitted for your region! Please verify the address on http://maps.google.com and then paste that Google Maps address into http://pinballmap.com/admin. Thanks!)\n
Location Name: name\n
Street: street\n
City: city\n
State: state\n
Zip: zip\n
Phone: phone\n
Website: website\n
Operator: operator\n
Machines: machines\n
Their Name: subname\n
Their Email: subemail\n
(entered from 127.0.0.1 via cleOS)\n
HERE
        )
      end

      post '/api/v1/locations/suggest.json', { region_id: @region.id.to_s, location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_phone: 'phone', location_website: 'website', location_operator: 'operator', location_machines: 'machines', submitter_name: 'subname', submitter_email: 'subemail' }, HTTP_USER_AGENT: 'cleOS'
      expect(response).to be_success

      expect(JSON.parse(response.body)['msg']).to eq("Thanks for entering that location. We'll get it in the system as soon as possible.")
    end
  end

  describe '#index' do
    it 'returns all regions within scope along with lmx data' do
      FactoryGirl.create(:location_machine_xref, location: @location, machine: FactoryGirl.create(:machine, id: 777, name: 'Cleo'))
      get "/api/v1/region/#{@region.name}/locations.json"

      expect(response.body).to include('Satchmo')
      expect(response.body).to include('777')
    end
  end

  describe '#update' do
    it 'throws an error if the location does not exist' do
      put '/api/v1/locations/666'

      expect(JSON.parse(response.body)['errors']).to eq('Failed to find location')
    end

    it 'only allows you to update description, website, type, and phone' do
      type = FactoryGirl.create(:location_type, name: 'bar')

      put '/api/v1/locations/' + @location.id.to_s + '.json?description=foo;website=http://bar;phone=5555555555;zip=97777;location_type=' + type.id.to_s
      expect(response).to be_success

      updated_location = Location.find(@location.id)

      expect(updated_location.description).to eq('foo')
      expect(updated_location.website).to eq('http://bar')
      expect(updated_location.phone).to eq('555-555-5555')
      expect(updated_location.zip).to eq('97203')
      expect(updated_location.location_type_id).to eq(type.id)

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      location = parsed_body['location']

      expect(location['description']).to eq('foo')
      expect(location['website']).to eq('http://bar')
      expect(location['phone']).to eq('555-555-5555')
      expect(location['zip']).to eq('97203')
      expect(location['location_type_id']).to eq(type.id)
    end

    it 'allows a blank location type' do
      type = FactoryGirl.create(:location_type, name: 'bar')
      @location.location_type_id = type.id

      put '/api/v1/locations/' + @location.id.to_s + '.json?description=foo;website=http://bar;phone=5555555555;zip=97777;location_type='
      expect(response).to be_success

      updated_location = Location.find(@location.id)

      expect(updated_location.location_type_id).to be_nil

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      location = parsed_body['location']

      expect(location['location_type_id']).to be_nil
    end

    it 'responds with an error if an invalid phone number is sent' do
      put '/api/v1/locations/' + @location.id.to_s + '.json?phone=baz'

      expect(response).to be_success

      expect(JSON.parse(response.body)['errors']).to eq(['Phone format invalid, please use ###-###-####'])

      put '/api/v1/locations/' + @location.id.to_s + '.json?phone=444-4444'

      expect(response).to be_success

      expect(JSON.parse(response.body)['errors']).to eq(['Phone format invalid, please use ###-###-####'])

      put '/api/v1/locations/' + @location.id.to_s + '.json?phone=11-444-4444'

      expect(response).to be_success

      expect(JSON.parse(response.body)['errors']).to eq(['Phone format invalid, please use ###-###-####'])
    end

    it 'blank phone number deletes phone number' do
      @location.phone = '555-555-5555'

      put '/api/v1/locations/' + @location.id.to_s + '.json?phone='
      expect(response).to be_success

      parsed_body = JSON.parse(response.body)
      location = parsed_body['location']

      expect(location['phone']).to eq(nil)
    end
  end

  describe '#closest_by_lat_lon' do
    it 'sends you the closest location to you, along with machines at the location' do
      get '/api/v1/locations/closest_by_lat_lon.json?lat=45.49;lon=-122.63'

      expect(JSON.parse(response.body)['errors']).to eq('No locations within 50 miles.')

      closest_location = FactoryGirl.create(:location, region: @region, name: 'Closest Location', street: '123 pine', city: 'portland', phone: '555-555-5555', state: 'OR', zip: '97203', lat: 45.49, lon: -122.63)
      FactoryGirl.create(:location_machine_xref, location: closest_location, machine: FactoryGirl.create(:machine, name: 'Cleo'))
      FactoryGirl.create(:location_machine_xref, location: closest_location, machine: FactoryGirl.create(:machine, name: 'Bawb'))
      FactoryGirl.create(:location_machine_xref, location: closest_location, machine: FactoryGirl.create(:machine, name: 'Sassy'))

      get "/api/v1/locations/closest_by_lat_lon.json?lat=#{closest_location.lat};lon=#{closest_location.lon}"

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      location = parsed_body['location']

      expect(location['name']).to eq('Closest Location')
      expect(location['street']).to eq('123 pine')
      expect(location['city']).to eq('portland')
      expect(location['state']).to eq('OR')
      expect(location['zip']).to eq('97203')
      expect(location['phone']).to eq('555-555-5555')
      expect(location['lat']).to eq('45.49')
      expect(location['lon']).to eq('-122.63')
      expect(location['machine_names']).to eq(%w(Bawb Cleo Sassy))
    end
  end

  describe '#machine_details' do
    it 'throws an error if the location does not exist' do
      get '/api/v1/locations/666/machine_details.json'

      expect(JSON.parse(response.body)['errors']).to eq('Failed to find location')
    end

    it 'displays details of machines at location' do
      FactoryGirl.create(:location_machine_xref, location: @location, machine: FactoryGirl.create(:machine, name: 'Cleo', year: 1980, manufacturer: 'Stern', ipdb_link: 'http://www.foo.com'))
      FactoryGirl.create(:location_machine_xref, location: @location, machine: FactoryGirl.create(:machine, name: 'Sass', year: 1960, manufacturer: 'Bally', ipdb_link: 'http://www.bar.com'))

      get '/api/v1/locations/' + @location.id.to_s + '/machine_details.json'
      expect(response).to be_success

      machines = JSON.parse(response.body)['machines']

      expect(machines[0]['name']).to eq('Cleo')
      expect(machines[0]['year']).to eq(1980)
      expect(machines[0]['manufacturer']).to eq('Stern')
      expect(machines[0]['ipdb_link']).to eq('http://www.foo.com')

      expect(machines[1]['name']).to eq('Sass')
      expect(machines[1]['year']).to eq(1960)
      expect(machines[1]['manufacturer']).to eq('Bally')
      expect(machines[1]['ipdb_link']).to eq('http://www.bar.com')
    end
  end
end
