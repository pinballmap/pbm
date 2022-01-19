require 'spec_helper'

describe Api::V1::LocationsController, type: :request do
  before(:each) do
    @region = FactoryBot.create(:region, name: 'portland', lat: 10, lon: 10)
    @another_region = FactoryBot.create(:region, name: 'seattle', lat: 20, lon: 20)
    @out_of_bounds_region = FactoryBot.create(:region, name: 'vancouver', lat: 100, lon: 100)
    @location = FactoryBot.create(:location, region: @region, name: 'Satchmo', state: 'OR', zip: '97203', lat: 42.18, lon: -71.18)
    @user = FactoryBot.create(:user, id: 111, username: 'cibw', email: 'foo@bar.com', region: @region, authentication_token: '1G8_s7P-V-4MGojaKD7a')
    @another_region_admin_user = FactoryBot.create(:user, id: 222, username: 'latguy', email: 'lat@guy.com', region: @another_region)
    FactoryBot.create(:user, email: 'super_admin@bar.com', region: nil, is_super_admin: 1)
  end

  describe '#suggest' do
    it 'errors when required fields are not sent' do
      expect(Pony).to_not receive(:mail)
      post '/api/v1/locations/suggest.json', params: { region_id: @region.id.to_s, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Location name, and a list of machines are required')

      expect(Pony).to_not receive(:mail)
      post '/api/v1/locations/suggest.json', params: { region_id: @region.id.to_s, location_machines: 'foo', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Location name, and a list of machines are required')

      expect(Pony).to_not receive(:mail)
      post '/api/v1/locations/suggest.json', params: { region_id: @region.id.to_s, location_name: 'baz', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Location name, and a list of machines are required')

      expect(Pony).to_not receive(:mail)
      post '/api/v1/locations/suggest.json', params: { region_id: @region.id.to_s, location_name: 'baz', location_machines: '', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Location name, and a list of machines are required')
    end

    it 'errors when region is not available' do
      post '/api/v1/locations/suggest.json', params: { region_id: -1, location_machines: 'foo', location_name: 'bar', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful

      expect(JSON.parse(response.body)['errors']).to eq('Failed to find region')
    end

    it 'errors when not authed' do
      post '/api/v1/locations/suggest.json', params: { region_id: @region.id.to_s, location_machines: 'foo', location_name: 'bar' }
      expect(response).to be_successful

      expect(JSON.parse(response.body)['errors']).to eq(Api::V1::LocationsController::AUTH_REQUIRED_MSG)
    end

    it 'emails admins on new location submission' do
      lt = FactoryBot.create(:location_type, name: 'type')
      o = FactoryBot.create(:operator, name: 'operator')
      z = FactoryBot.create(:zone, name: 'zone')

      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          to: ['foo@bar.com'],
          bcc: ['super_admin@bar.com'],
          from: 'admin@pinballmap.com',
          subject: 'PBM - New location suggested for the portland pinball map',
          body: <<HERE
    Dear Admin: You can approve this location with the click of a button at http://www.example.com/admin/suggested_location\n\nClick the "(i)" to the right, and then click the big "APPROVE LOCATION" button at the top.\n\nBut first, check that the location is not already on the map, add any missing fields (like Type, Phone, and Website), confirm the address via https://maps.google.com, and make sure it's a public venue. Thanks!!\n
Location Name: name\n
Street: street\n
City: city\n
State: state\n
Zip: zip\n
Country: \n
Phone: phone\n
Website: website\n
Type: type\n
Operator: operator\n
Zone: zone\n
Comments: comments\n
Machines: machines\n
(entered from 127.0.0.1 via cleOS by cibw (foo@bar.com))\n
HERE
        )
      end

      post '/api/v1/locations/suggest.json', params: { region_id: @region.id.to_s, location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_phone: 'phone', location_website: 'website', location_type: 'type', location_operator: 'operator', location_zone: 'zone', location_comments: 'comments', location_machines: 'machines', submitter_name: 'subname', submitter_email: 'subemail', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }, headers: { HTTP_USER_AGENT: 'cleOS' }
      expect(response).to be_successful

      expect(JSON.parse(response.body)['msg']).to eq("Thanks for entering that location. We'll get it in the system as soon as possible.")
      expect(UserSubmission.all.count).to eq(1)
      expect(UserSubmission.first.submission_type).to eq(UserSubmission::SUGGEST_LOCATION_TYPE)

      expect(SuggestedLocation.first.location_type).to eq(lt)
      expect(SuggestedLocation.first.operator).to eq(o)
      expect(SuggestedLocation.first.zone).to eq(z)
    end

    it 'emails super admins on new location submission where user has no lat/lon reported' do
      lt = FactoryBot.create(:location_type, name: 'type')
      o = FactoryBot.create(:operator, name: 'operator')
      z = FactoryBot.create(:zone, name: 'zone')

      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          to: ['super_admin@bar.com'],
          from: 'admin@pinballmap.com',
          bcc: ['super_admin@bar.com'],
          subject: 'PBM - New location suggested for pinball map',
          body: <<HERE
    Dear Admin: You can approve this location with the click of a button at http://www.example.com/admin/suggested_location\n\nClick the "(i)" to the right, and then click the big "APPROVE LOCATION" button at the top.\n\nBut first, check that the location is not already on the map, add any missing fields (like Type, Phone, and Website), confirm the address via https://maps.google.com, and make sure it's a public venue. Thanks!!\n
Location Name: name\n
Street: street\n
City: city\n
State: state\n
Zip: zip\n
Country: \n
Phone: phone\n
Website: website\n
Type: type\n
Operator: operator\n
Zone: zone\n
Comments: comments\n
Machines: machines\n
(entered from 127.0.0.1 via cleOS by cibw (foo@bar.com))\n
HERE
        )
      end

      post '/api/v1/locations/suggest.json', params: { location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_phone: 'phone', location_website: 'website', location_type: 'type', location_operator: 'operator', location_zone: 'zone', location_comments: 'comments', location_machines: 'machines', submitter_name: 'subname', submitter_email: 'subemail', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }, headers: { HTTP_USER_AGENT: 'cleOS' }
      expect(response).to be_successful

      expect(JSON.parse(response.body)['msg']).to eq("Thanks for entering that location. We'll get it in the system as soon as possible.")
      expect(UserSubmission.all.count).to eq(1)
      expect(UserSubmission.first.submission_type).to eq(UserSubmission::SUGGEST_LOCATION_TYPE)

      expect(SuggestedLocation.first.location_type).to eq(lt)
      expect(SuggestedLocation.first.operator).to eq(o)
      expect(SuggestedLocation.first.zone).to eq(z)
    end

    it 'searches boundary boxes by transmitted lat/lon to determine region' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          to: ['lat@guy.com'],
          bcc: ['super_admin@bar.com'],
          from: 'admin@pinballmap.com',
          subject: 'PBM - New location suggested for the seattle pinball map',
          body: <<HERE
    Dear Admin: You can approve this location with the click of a button at http://www.example.com/admin/suggested_location\n\nClick the "(i)" to the right, and then click the big "APPROVE LOCATION" button at the top.\n\nBut first, check that the location is not already on the map, add any missing fields (like Type, Phone, and Website), confirm the address via https://maps.google.com, and make sure it's a public venue. Thanks!!\n
Location Name: name\n
Street: \n
City: \n
State: \n
Zip: \n
Country: \n
Phone: \n
Website: \n
Type: \n
Operator: \n
Zone: \n
Comments: \n
Machines: machines\n
(entered from 127.0.0.1 via cleOS by cibw (foo@bar.com))\n
HERE
        )
      end

      post '/api/v1/locations/suggest.json', params: { region_id: nil, location_name: 'name', location_machines: 'machines', submitter_name: 'subname', submitter_email: 'subemail', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', lat: 20, lon: 20 }, headers: { HTTP_USER_AGENT: 'cleOS' }
    end

    it 'tags a user when appropriate' do
      post '/api/v1/locations/suggest.json', params: { region_id: @region.id.to_s, location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_phone: 'phone', location_website: 'website', location_type: 'type', location_operator: 'operator', location_comments: 'comments', location_machines: 'machines', submitter_name: 'subname', submitter_email: 'subemail', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', HTTP_USER_AGENT: 'cleOS' }

      expect(response).to be_successful
      expect(UserSubmission.first.user_id).to eq(111)
    end

    it 'does not bomb out when operator and type and zone are blank' do
      post '/api/v1/locations/suggest.json', params: { region_id: @region.id.to_s, location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_phone: 'phone', location_website: 'website', location_type: nil, location_zone: '', location_operator: '', location_comments: 'comments', location_machines: 'machines', submitter_name: 'subname', submitter_email: 'subemail', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', HTTP_USER_AGENT: 'cleOS' }

      expect(response).to be_successful
      expect(SuggestedLocation.first.location_type).to eq(nil)
      expect(SuggestedLocation.first.operator).to eq(nil)
      expect(SuggestedLocation.first.zone).to eq(nil)
    end

    it 'lets you enter by operator_id and location_type_id and zone_id' do
      lt = FactoryBot.create(:location_type, name: 'cool type')
      o = FactoryBot.create(:operator, name: 'cool operator')
      z = FactoryBot.create(:zone, name: 'cool zone')

      expect(Pony).to receive(:mail).twice do |mail|
        expect(mail).to include(
          to: ['foo@bar.com'],
          bcc: ['super_admin@bar.com'],
          from: 'admin@pinballmap.com',
          subject: 'PBM - New location suggested for the portland pinball map',
          body: <<HERE
    Dear Admin: You can approve this location with the click of a button at http://www.example.com/admin/suggested_location\n\nClick the "(i)" to the right, and then click the big "APPROVE LOCATION" button at the top.\n\nBut first, check that the location is not already on the map, add any missing fields (like Type, Phone, and Website), confirm the address via https://maps.google.com, and make sure it's a public venue. Thanks!!\n
Location Name: name\n
Street: street\n
City: city\n
State: state\n
Zip: zip\n
Country: \n
Phone: phone\n
Website: website\n
Type: cool type\n
Operator: cool operator\n
Zone: cool zone\n
Comments: comments\n
Machines: machines\n
(entered from 127.0.0.1 via cleOS by cibw (foo@bar.com))\n
HERE
        )
      end

      post '/api/v1/locations/suggest.json', params: { region_id: @region.id.to_s, location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_phone: 'phone', location_website: 'website', location_type: lt.id, location_operator: o.id, location_zone: z.id, location_comments: 'comments', location_machines: 'machines', submitter_name: 'subname', submitter_email: 'subemail', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }, headers: { HTTP_USER_AGENT: 'cleOS' }
      expect(response).to be_successful

      post '/api/v1/locations/suggest.json', params: { region_id: @region.id.to_s, location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_phone: 'phone', location_website: 'website', location_type: lt.id, location_operator: o.id, location_zone: z.id, location_comments: 'comments', location_machines: 'machines', submitter_name: 'subname', submitter_email: 'subemail', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }, headers: { HTTP_USER_AGENT: 'cleOS' }, as: :json
      expect(response).to be_successful

      expect(SuggestedLocation.first.location_type).to eq(lt)
      expect(SuggestedLocation.first.operator).to eq(o)
      expect(SuggestedLocation.first.zone).to eq(z)

      expect(SuggestedLocation.second.location_type).to eq(lt)
      expect(SuggestedLocation.second.operator).to eq(o)
      expect(SuggestedLocation.second.zone).to eq(z)
    end
  end

  describe '#index' do
    it 'allows token authentication via query params' do
      get "/api/v1/region/#{@region.name}/locations.json", params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      assert_response :success
    end

    it 'allows token authentication via request headers' do
      get "/api/v1/region/#{@region.name}/locations.json", params: { headers: { 'X-User-Email' => 'foo@bar.com', 'X-User-Token' => '1G8_s7P-V-4MGojaKD7a' } }
      assert_response :success
    end

    it 'forces you to filter' do
      FactoryBot.create(:location, region: FactoryBot.create(:region, name: 'la'), name: 'Cleo')
      FactoryBot.create(:location, region: FactoryBot.create(:region, name: 'chicago'), name: 'Bawb')

      get '/api/v1/locations.json'

      expect(JSON.parse(response.body)['errors']).to eq(Api::V1::LocationsController::FILTERING_REQUIRED_MSG)
    end

    it 'respects stern_army filter' do
      FactoryBot.create(:location, region: FactoryBot.create(:region, name: 'la'), name: 'Cleo', is_stern_army: 't')
      FactoryBot.create(:location, region: FactoryBot.create(:region, name: 'chicago'), name: 'Bawb')

      get '/api/v1/locations.json?by_is_stern_army=1'

      expect(response.body).to include('Cleo')
    end

    it 'returns all locations in a region within scope along with lmx data' do
      FactoryBot.create(:location, region: FactoryBot.create(:region, name: 'chicago'), name: 'Bawb')

      lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine, id: 777, name: 'Cleo'))
      FactoryBot.create(:machine_condition, location_machine_xref_id: lmx.id, comment: 'foo bar')

      get "/api/v1/region/#{@region.name}/locations.json"

      expect(response.body).to include('Satchmo')
      expect(response.body).to include('777')
      expect(response.body).to include('foo bar')
      expect(response.body).to_not include('Bawb')
    end

    it 'respects by_ipdb_id / by_opdb_id filters' do
      lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine, id: 777, name: 'Cleo', ipdb_id: 999, opdb_id: 'b33f'))
      FactoryBot.create(:machine_condition, location_machine_xref_id: lmx.id, comment: 'foo bar')
      get "/api/v1/region/#{@region.name}/locations.json", params: { by_ipdb_id: 999 }

      expect(response.body).to include('Satchmo')
      expect(response.body).to include('777')
      expect(response.body).to include('foo bar')

      get "/api/v1/region/#{@region.name}/locations.json", params: { by_opdb_id: 'b33f' }

      expect(response.body).to include('Satchmo')
      expect(response.body).to include('777')
      expect(response.body).to include('foo bar')
    end

    it 'respects regionless_only filter' do
      FactoryBot.create(:location, region: @region, name: 'Cleo')
      FactoryBot.create(:location, region: nil, name: 'Regionless')
      get '/api/v1/locations.json', params: { regionless_only: 1 }

      expect(response.body).to include('Regionless')
      expect(response.body).to_not include('Cleo')
    end

    it 'respects is_stern_army filter' do
      FactoryBot.create(:location, region: @region, name: 'Stern Army Place', is_stern_army: 't')
      get "/api/v1/region/#{@region.name}/locations.json", params: { by_is_stern_army: 1 }

      expect(response.body).to include('Stern Army Place')
      expect(response.body).to_not include('Satchmo')
    end

    it 'returns username' do
      ssw = FactoryBot.create(:user, username: 'ssw')
      lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine, id: 777, name: 'Cleo'), user: ssw)
      FactoryBot.create(:machine_condition, location_machine_xref_id: lmx.id, comment: 'baz', user: ssw)
      get "/api/v1/region/#{@region.name}/locations.json"

      expect(response.body.scan('ssw').size).to eq(3)
    end

    it 'returns num_machines' do
      FactoryBot.create(:location_machine_xref, location: @location)
      get "/api/v1/region/#{@region.name}/locations.json"
      parsed_body = JSON.parse(response.body)

      location = parsed_body['locations'][0]
      expect(location['num_machines']).to eq(1)
    end

    it 'omits lmx/condition info when you use the no_details param' do
      FactoryBot.create(:location_machine_xref, location: @location)
      get "/api/v1/region/#{@region.name}/locations.json?no_details=1"

      expect(response.body.scan('location_machine_xrefs').size).to eq(0)
      expect(response.body.scan('machine_conditions').size).to eq(0)
      expect(response.body.scan('phone').size).to eq(0)
      expect(response.body.scan('website').size).to eq(0)
      expect(response.body.scan('description').size).to eq(0)
      expect(response.body.scan('created_at').size).to eq(0)
      expect(response.body.scan('updated_at').size).to eq(0)
      expect(response.body.scan('date_last_updated').size).to eq(0)
      expect(response.body.scan('last_updated_by_user_id').size).to eq(0)
      expect(response.body.scan('region_id').size).to eq(0)

      expect(response.body.scan('id').size).to_not eq(0)
      expect(response.body.scan('name').size).to_not eq(0)
      expect(response.body.scan('street').size).to_not eq(0)
      expect(response.body.scan('state').size).to_not eq(0)
      expect(response.body.scan('zip').size).to_not eq(0)
      expect(response.body.scan('lat').size).to_not eq(0)
      expect(response.body.scan('lon').size).to_not eq(0)
      expect(response.body.scan('city').size).to_not eq(0)
      expect(response.body.scan('num_machines').size).to_not eq(0)
      expect(response.body.scan('last_updated_by_username').size).to_not eq(0)
    end
  end

  describe '#update' do
    it 'throws an error if the location does not exist' do
      put '/api/v1/locations/666', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(JSON.parse(response.body)['errors']).to eq('Failed to find location')
    end

    it 'throws an error if you are not authed' do
      put '/api/v1/locations/' + @location.id.to_s + '.json', params: { description: 'foo', website: 'http://bar', phone: '5555555555', zip: '97777' }

      expect(JSON.parse(response.body)['errors']).to eq(Api::V1::LocationsController::AUTH_REQUIRED_MSG)
    end

    it 'only allows you to update description, website, type, operator, and phone' do
      type = FactoryBot.create(:location_type, name: 'bar')
      operator = FactoryBot.create(:operator, name: 'CleoWorld')

      put '/api/v1/locations/' + @location.id.to_s + '.json', params: { description: 'foo', website: 'http://bar', phone: '5038471772', zip: '97777', location_type: type.id.to_s, operator_id: operator.id.to_s, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful

      updated_location = @location.reload

      expect(updated_location.description).to eq('foo')
      expect(updated_location.website).to eq('http://bar')
      expect(updated_location.phone).to eq('5038471772')
      expect(updated_location.zip).to eq('97203')
      expect(updated_location.location_type_id).to eq(type.id)
      expect(updated_location.operator_id).to eq(operator.id)

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      location = parsed_body['location']

      expect(location['description']).to eq('foo')
      expect(location['website']).to eq('http://bar')
      expect(location['phone']).to eq('5038471772')
      expect(location['zip']).to eq('97203')
      expect(location['location_type_id']).to eq(type.id)
      expect(location['operator_id']).to eq(operator.id)
    end

    it 'allows a blank location type' do
      type = FactoryBot.create(:location_type, name: 'bar')
      @location.location_type_id = type.id

      put '/api/v1/locations/' + @location.id.to_s + '.json', params: { description: 'foo', website: 'http://bar', phone: '5039183717', zip: '97777', location_type: '', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful

      updated_location = @location.reload

      expect(updated_location.location_type_id).to be_nil

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      location = parsed_body['location']

      expect(location['location_type_id']).to be_nil
    end

    it 'accepts location_type as a Fixnum' do
      type = FactoryBot.create(:location_type, name: 'bar')
      new_type = FactoryBot.create(:location_type, name: 'baz')
      @location.location_type_id = type.id

      put '/api/v1/locations/' + @location.id.to_s + '.json', params: { location_type: new_type.id, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful

      updated_location = @location.reload

      expect(updated_location.location_type_id).to be(new_type.id)
    end

    it 'responds with an error if an invalid phone number is sent' do
      put '/api/v1/locations/' + @location.id.to_s + '.json', params: { phone: 'baz', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful

      expect(JSON.parse(response.body)['errors']).to eq(['Invalid phone format.'])

      put '/api/v1/locations/' + @location.id.to_s + '.json', params: { phone: '444-4444', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful

      expect(JSON.parse(response.body)['errors']).to eq(['Invalid phone format.'])

      put '/api/v1/locations/' + @location.id.to_s + '.json', params: { phone: '11-444-4444', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful

      expect(JSON.parse(response.body)['errors']).to eq(['Invalid phone format.'])
    end

    it 'blank phone number deletes phone number' do
      @location.phone = '503-294-9948'

      put '/api/v1/locations/' + @location.id.to_s + '.json', params: { phone: nil, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful

      parsed_body = JSON.parse(response.body)
      location = parsed_body['location']

      expect(location['phone']).to eq(nil)
    end

    it 'tags update with user_id when authenticating' do
      put '/api/v1/locations/' + @location.id.to_s + '.json', params: { description: 'foo', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful

      updated_location = @location.reload

      expect(updated_location.description).to eq('foo')
      expect(updated_location.last_updated_by_user_id).to eq(111)
    end
  end

  describe '#closest_by_address' do
    it 'sends you the closest location to you, along with machines at the location' do
      get '/api/v1/locations/closest_by_address.json', params: { address: '97202' }

      expect(JSON.parse(response.body)['errors']).to eq('No locations within 50 miles.')

      closest_location = FactoryBot.create(:location, region: @region, name: 'Closest Location', street: '123 pine', city: 'portland', phone: '503-924-9188', state: 'OR', zip: '97202', lat: 45.49, lon: -122.63)
      FactoryBot.create(:location_machine_xref, location: closest_location, machine: FactoryBot.create(:machine, name: 'Cleo'))
      FactoryBot.create(:location_machine_xref, location: closest_location, machine: FactoryBot.create(:machine, name: 'Bawb'))
      FactoryBot.create(:location_machine_xref, location: closest_location, machine: FactoryBot.create(:machine, name: 'Sassy'))

      get '/api/v1/locations/closest_by_address.json', params: { address: '97202' }

      sleep 1

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      location = parsed_body['location']

      expect(location['name']).to eq('Closest Location')
      expect(location['street']).to eq('123 pine')
      expect(location['city']).to eq('portland')
      expect(location['state']).to eq('OR')
      expect(location['zip']).to eq('97202')
      expect(location['phone']).to eq('503-924-9188')
      expect(location['lat']).to eq('45.49')
      expect(location['lon']).to eq('-122.63')
      expect(location['machine_names']).to eq(%w[Bawb Cleo Sassy])
    end

    it 'sends you multiple locations if you use the send_all_within_distance flag' do
      close_location_one = FactoryBot.create(:location, region: @region, lat: 45.49, lon: -122.63)
      close_location_two = FactoryBot.create(:location, region: @region, lat: 45.49, lon: -122.631)
      close_location_three = FactoryBot.create(:location, region: @region, lat: 45.491, lon: -122.63)
      FactoryBot.create(:location, region: @region, lat: 5.49, lon: 22.63)

      get '/api/v1/locations/closest_by_address.json', params: { address: '97202', send_all_within_distance: 1 }

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      locations = parsed_body['locations']
      expect(locations[0]['id']).to eq(close_location_three.id)
      expect(locations[1]['id']).to eq(close_location_two.id)
      expect(locations[2]['id']).to eq(close_location_one.id)
    end

    it 'respects no_details and shows fewer location fields' do
      FactoryBot.create(:location, region: @region, lat: 45.49, lon: -122.63)
      FactoryBot.create(:location, region: @region, lat: 5.49, lon: 22.63)

      get '/api/v1/locations/closest_by_address.json', params: { address: '97202', send_all_within_distance: 1, no_details: 1 }

      expect(response.body.scan('country').size).to eq(0)
      expect(response.body.scan('last_updated_by_user_id').size).to eq(0)
      expect(response.body.scan('description').size).to eq(0)
      expect(response.body.scan('region_id').size).to eq(0)
      expect(response.body.scan('zone_id').size).to eq(0)
      expect(response.body.scan('website').size).to eq(0)
      expect(response.body.scan('phone').size).to eq(0)

      expect(response.body.scan('id').size).to_not eq(0)
      expect(response.body.scan('name').size).to_not eq(0)
      expect(response.body.scan('lat').size).to_not eq(0)
      expect(response.body.scan('lon').size).to_not eq(0)
      expect(response.body.scan('city').size).to_not eq(0)
      expect(response.body.scan('is_stern_army').size).to_not eq(0)
    end

    it 'respects manufacturer filter' do
      stern_closest = FactoryBot.create(:location, region: @region, name: 'Closest Stern Location', street: '123 pine', city: 'portland', phone: '503-924-9188', state: 'OR', zip: '97202', lat: 45.49, lon: -122.63)
      FactoryBot.create(:location_machine_xref, location: stern_closest, machine: FactoryBot.create(:machine, name: 'Cleo', manufacturer: 'Stern'))
      FactoryBot.create(:location_machine_xref, location: stern_closest, machine: FactoryBot.create(:machine, name: 'Sass', manufacturer: 'Stern'))

      closest_location = FactoryBot.create(:location, region: @region, name: 'Closest Location', street: '123 pine', city: 'portland', phone: '503-924-9188', state: 'OR', zip: '97202', lat: 45.49, lon: -122.63)
      FactoryBot.create(:location_machine_xref, location: closest_location, machine: FactoryBot.create(:machine, name: 'Sass', manufacturer: 'Williams'))

      get '/api/v1/locations/closest_by_address.json', params: { address: '97202', manufacturer: 'Stern', send_all_within_distance: 1 }

      sleep 1

      parsed_body = JSON.parse(response.body)
      locations = parsed_body['locations']
      expect(locations.size).to eq(1)

      expect(locations[0]['name']).to eq('Closest Stern Location')
    end
  end

  describe '#closest_by_lat_lon' do
    it 'sends you the closest location to you, along with machines at the location' do
      get '/api/v1/locations/closest_by_lat_lon.json', params: { lat: 45.49, lon: -122.63 }

      expect(JSON.parse(response.body)['errors']).to eq('No locations within 50 miles.')

      closest_location = FactoryBot.create(:location, region: @region, name: 'Closest Location', street: '123 pine', city: 'portland', phone: '503-928-9288', state: 'OR', zip: '97203', lat: 45.49, lon: -122.63)
      FactoryBot.create(:location_machine_xref, location: closest_location, machine: FactoryBot.create(:machine, id: 200, name: 'Cleo'))
      FactoryBot.create(:location_machine_xref, location: closest_location, machine: FactoryBot.create(:machine, id: 201, name: 'Bawb'))
      FactoryBot.create(:location_machine_xref, location: closest_location, machine: FactoryBot.create(:machine, id: 202, name: 'Sassy'))

      get '/api/v1/locations/closest_by_lat_lon.json', params: { lat: closest_location.lat, lon: closest_location.lon }

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      location = parsed_body['location']

      expect(location['name']).to eq('Closest Location')
      expect(location['street']).to eq('123 pine')
      expect(location['city']).to eq('portland')
      expect(location['state']).to eq('OR')
      expect(location['zip']).to eq('97203')
      expect(location['phone']).to eq('503-928-9288')
      expect(location['lat']).to eq('45.49')
      expect(location['lon']).to eq('-122.63')
      expect(location['machine_names']).to eq(%w[Bawb Cleo Sassy])
      expect(location['machine_ids']).to eq([201, 200, 202])
    end

    it 'sends you multiple locations if you use the send_all_within_distance flag' do
      close_location_one = FactoryBot.create(:location, region: @region, lat: 45.49, lon: -122.63)
      close_location_two = FactoryBot.create(:location, region: @region, lat: 45.49, lon: -122.631)
      close_location_three = FactoryBot.create(:location, region: @region, lat: 45.491, lon: -122.63)
      FactoryBot.create(:location, region: @region, lat: 5.49, lon: 22.63)

      get '/api/v1/locations/closest_by_lat_lon.json', params: { lat: close_location_one.lat, lon: close_location_one.lon, send_all_within_distance: 1 }

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      locations = parsed_body['locations']
      expect(locations[0]['id']).to eq(close_location_one.id)
      expect(locations[1]['id']).to eq(close_location_two.id)
      expect(locations[2]['id']).to eq(close_location_three.id)
    end

    it 'respects no_details and shows fewer location fields' do
      closest_location = FactoryBot.create(:location, region: @region, lat: 45.49, lon: -122.63)
      FactoryBot.create(:location, region: @region, lat: 5.49, lon: 22.63)

      get '/api/v1/locations/closest_by_lat_lon.json', params: { lat: closest_location.lat, lon: closest_location.lon, send_all_within_distance: 1, no_details: 1 }

      expect(response.body.scan('country').size).to eq(0)
      expect(response.body.scan('last_updated_by_user_id').size).to eq(0)
      expect(response.body.scan('description').size).to eq(0)
      expect(response.body.scan('region_id').size).to eq(0)
      expect(response.body.scan('zone_id').size).to eq(0)
      expect(response.body.scan('website').size).to eq(0)
      expect(response.body.scan('phone').size).to eq(0)

      expect(response.body.scan('id').size).to_not eq(0)
      expect(response.body.scan('name').size).to_not eq(0)
      expect(response.body.scan('lat').size).to_not eq(0)
      expect(response.body.scan('lon').size).to_not eq(0)
      expect(response.body.scan('city').size).to_not eq(0)
      expect(response.body.scan('is_stern_army').size).to_not eq(0)
    end

    it 'respects filters' do
      location_type = FactoryBot.create(:location_type)
      machine = FactoryBot.create(:machine)
      operator = FactoryBot.create(:operator)

      close_location_one = FactoryBot.create(:location, region: @region, lat: 45.49, lon: -122.63)
      close_location_two = FactoryBot.create(:location, region: @region, lat: 45.49, lon: -122.631, operator: operator, location_type: location_type)
      close_location_three = FactoryBot.create(:location, region: @region, lat: 45.491, lon: -122.63, operator: operator, location_type: location_type)
      FactoryBot.create(:location, region: @region, lat: 5.49, lon: 22.63)

      FactoryBot.create(:location_machine_xref, location: close_location_two, machine: machine)
      FactoryBot.create(:location_machine_xref, location: close_location_three)
      FactoryBot.create(:location_machine_xref, location: close_location_three)
      FactoryBot.create(:location_machine_xref, location: close_location_three)

      get '/api/v1/locations/closest_by_lat_lon.json', params: { lat: close_location_one.lat, lon: close_location_one.lon, by_type_id: location_type.id }

      location = JSON.parse(response.body)['location']
      expect(location['id']).to eq(close_location_two.id)

      get '/api/v1/locations/closest_by_lat_lon.json', params: { lat: close_location_one.lat, lon: close_location_one.lon, by_operator_id: operator.id }

      location = JSON.parse(response.body)['location']
      expect(location['id']).to eq(close_location_two.id)

      get '/api/v1/locations/closest_by_lat_lon.json', params: { lat: close_location_one.lat, lon: close_location_one.lon, by_machine_id: machine.id }

      location = JSON.parse(response.body)['location']
      expect(location['id']).to eq(close_location_two.id)

      get '/api/v1/locations/closest_by_lat_lon.json', params: { lat: close_location_one.lat, lon: close_location_one.lon, by_at_least_n_machines_type: 3 }

      location = JSON.parse(response.body)['location']
      expect(location['id']).to eq(close_location_three.id)

      get '/api/v1/locations/closest_by_lat_lon.json', params: { lat: close_location_one.lat, lon: close_location_one.lon, by_type_id: location_type.id, send_all_within_distance: 1 }

      locations = JSON.parse(response.body)['locations']
      expect(locations.size).to eq(2)
      expect(locations[0]['id']).to eq(close_location_two.id)
      expect(locations[1]['id']).to eq(close_location_three.id)

      get '/api/v1/locations/closest_by_lat_lon.json', params: { lat: close_location_one.lat, lon: close_location_one.lon, by_operator_id: operator.id, send_all_within_distance: 1 }

      locations = JSON.parse(response.body)['locations']
      expect(locations.size).to eq(2)
      expect(locations[0]['id']).to eq(close_location_two.id)
      expect(locations[1]['id']).to eq(close_location_three.id)

      get '/api/v1/locations/closest_by_lat_lon.json', params: { lat: close_location_one.lat, lon: close_location_one.lon, by_machine_id: machine.id, send_all_within_distance: 1 }

      locations = JSON.parse(response.body)['locations']
      expect(locations.size).to eq(1)
      expect(locations[0]['id']).to eq(close_location_two.id)

      get '/api/v1/locations/closest_by_lat_lon.json', params: { lat: close_location_one.lat, lon: close_location_one.lon, by_at_least_n_machines_type: 3, send_all_within_distance: 1 }

      locations = JSON.parse(response.body)['locations']
      expect(locations.size).to eq(1)
      expect(locations[0]['id']).to eq(close_location_three.id)
    end

    it 'lets you filter by a specific machine and N machines at the same time' do
      machine = FactoryBot.create(:machine)

      close_location_one = FactoryBot.create(:location, region: @region, lat: 45.49, lon: -122.63)
      close_location_two = FactoryBot.create(:location, region: @region, lat: 45.49, lon: -122.631)
      FactoryBot.create(:location, region: @region, lat: 5.49, lon: 22.63)

      FactoryBot.create(:location_machine_xref, location: close_location_one, machine: machine)
      FactoryBot.create(:location_machine_xref, location: close_location_two, machine: machine)
      FactoryBot.create(:location_machine_xref, location: close_location_two)
      FactoryBot.create(:location_machine_xref, location: close_location_two)

      get '/api/v1/locations/closest_by_lat_lon.json', params: { lat: close_location_one.lat, lon: close_location_one.lon, by_at_least_n_machines_type: 2, by_machine_id: machine.id }

      location = JSON.parse(response.body)['location']
      expect(location['id']).to eq(close_location_two.id)
    end
  end

  describe '#machine_details' do
    it 'throws an error if the location does not exist' do
      get '/api/v1/locations/666/machine_details.json'

      expect(JSON.parse(response.body)['errors']).to eq('Failed to find location')
    end

    it 'displays details of machines at location' do
      FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine, id: 123, name: 'Cleo', year: 1980, manufacturer: 'Stern', ipdb_link: 'http://www.foo.com', ipdb_id: nil))
      FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine, id: 456, name: 'Sass', year: 1960, manufacturer: 'Bally', ipdb_link: 'http://www.bar.com', ipdb_id: 123))

      get '/api/v1/locations/' + @location.id.to_s + '/machine_details.json'
      expect(response).to be_successful

      machines = JSON.parse(response.body)['machines']

      expect(machines[0]['id']).to eq(123)
      expect(machines[0]['name']).to eq('Cleo')
      expect(machines[0]['year']).to eq(1980)
      expect(machines[0]['manufacturer']).to eq('Stern')
      expect(machines[0]['ipdb_link']).to eq('http://www.foo.com')
      expect(machines[0]['ipdb_id']).to be_nil

      expect(machines[1]['id']).to eq(456)
      expect(machines[1]['name']).to eq('Sass')
      expect(machines[1]['year']).to eq(1960)
      expect(machines[1]['manufacturer']).to eq('Bally')
      expect(machines[1]['ipdb_link']).to eq('http://www.bar.com')
      expect(machines[1]['ipdb_id']).to eq(123)
    end
  end

  describe '#confirm_location' do
    it 'sets date_last_updated on location' do
      Timecop.travel(Time.zone.local(2010, 6, 1, 13, 0, 0)) do
        put '/api/v1/locations/' + @location.id.to_s + '/confirm.json', params: { user_token: '1G8_s7P-V-4MGojaKD7a', user_email: 'foo@bar.com' }
      end
      expect(response).to be_successful

      updated_location = @location.reload
      expect(updated_location.last_updated_by_user).to eq(@user)
      expect(updated_location.date_last_updated.to_s).to eq('2010-06-01')

      expect(JSON.parse(response.body)['msg']).to eq('Thanks for confirming the line-up at this location!')
    end

    it 'throws an error if the location does not exist' do
      put '/api/v1/locations/666/confirm.json', params: { user_token: '1G8_s7P-V-4MGojaKD7a', user_email: 'foo@bar.com' }

      expect(JSON.parse(response.body)['errors']).to eq('Failed to find location')
    end

    it 'throws an error if you are not authed' do
      put '/api/v1/locations/' + @location.id.to_s + '/confirm.json'

      expect(JSON.parse(response.body)['errors']).to eq(Api::V1::LocationsController::AUTH_REQUIRED_MSG)
    end
  end

  describe '#by_city_id' do
    it 'returns all locations within a city and state' do
      FactoryBot.create(:location, city: 'Portland', state: 'ME')
      FactoryBot.create(:location, city: 'Portland', state: 'OR')

      get '/api/v1/locations.json/?by_state_id=OR;by_city_id=Portland'

      expect(response.body).to include('OR')
      expect(response.body).to_not include('ME')
    end

    it 'forces you to filter by_state_id' do
      get '/api/v1/locations.json/?by_state_id=OR'

      expect(JSON.parse(response.body)['errors']).to eq(Api::V1::LocationsController::FILTERING_REQUIRED_MSG)
    end
  end

  describe '#show' do
    it 'returns all regions within scope along with lmx data' do
      lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine, id: 777, name: 'Cleo'))
      FactoryBot.create(:machine_condition, location_machine_xref_id: lmx.id, comment: 'foo bar')
      FactoryBot.create(:machine_score_xref, location_machine_xref: lmx, score: 567)
      get "/api/v1/region/#{@region.name}/locations/#{@location.id}.json"

      expect(response.body).to include('Satchmo')
      expect(response.body).to include('777')
      expect(response.body).to include('foo bar')
      expect(response.body).to include('567')
    end
  end

  describe '#autocomplete_city' do
    it 'should do a fuzzy search on city name and return a list of in-scope city names + state' do
      FactoryBot.create(:location, city: 'Portland', state: 'ME')
      FactoryBot.create(:location, city: 'Portland', state: 'OR')
      FactoryBot.create(:location, city: 'Beaverton')

      get '/api/v1/locations/autocomplete_city', params: { name: 'port' }

      expect(response.body).to eq(<<HERE.strip)
[{"label":"Portland, OR","value":"Portland, OR"},{"label":"Portland, ME","value":"Portland, ME"}]
HERE

      get '/api/v1/locations/autocomplete_city', params: { name: 'portland o' }

      expect(response.body).to eq(<<HERE.strip)
[{"label":"Portland, OR","value":"Portland, OR"}]
HERE
    end

    it 'should return an empty array if no found results' do
      FactoryBot.create(:location, city: 'Portland', state: 'ME')
      FactoryBot.create(:location, city: 'Portland', state: 'OR')
      FactoryBot.create(:location, city: 'Beaverton')

      get '/api/v1/locations/autocomplete_city', params: { name: 'asdf' }

      expect(response.body).to eq('[]')
    end
  end

  describe '#autocomplete' do
    it 'should do a fuzzy search on name and return a list of in-scope names and IDs' do
      FactoryBot.create(:location, name: 'foo')
      bar = FactoryBot.create(:location, name: 'bar')
      barfoo = FactoryBot.create(:location, name: 'barfoo')

      get '/api/v1/locations/autocomplete', params: { name: 'ar' }

      expect(response.body).to eq(<<HERE.strip)
[{"label":"bar (Portland, OR)","value":"bar","id":#{bar.id}},{"label":"barfoo (Portland, OR)","value":"barfoo","id":#{barfoo.id}}]
HERE
    end

    it 'should return an empty array if no found results' do
      FactoryBot.create(:location, name: 'foo')
      FactoryBot.create(:location, name: 'bar')
      FactoryBot.create(:location, name: 'barfoo')

      get '/api/v1/locations/autocomplete', params: { name: 'asdf' }

      expect(response.body).to eq('[]')
    end

    it 'handles normal and iOS apostrophes' do
      FactoryBot.create(:location, name: 'foo')
      bar = FactoryBot.create(:location, name: "Clark's Castle")
      barfoo = FactoryBot.create(:location, name: 'Clark’s Castle')

      get '/api/v1/locations/autocomplete', params: { name: "Clark's" }

      expect(response.body).to eq(<<HERE.strip)
[{"label":"Clark's Castle (Portland, OR)","value":"Clark's Castle","id":#{bar.id}},{"label":"Clark’s Castle (Portland, OR)","value":"Clark’s Castle","id":#{barfoo.id}}]
HERE

      get '/api/v1/locations/autocomplete', params: { name: 'Clark’s' }

      expect(response.body).to eq(<<HERE.strip)
[{"label":"Clark's Castle (Portland, OR)","value":"Clark's Castle","id":#{bar.id}},{"label":"Clark’s Castle (Portland, OR)","value":"Clark’s Castle","id":#{barfoo.id}}]
HERE
    end
  end
end
