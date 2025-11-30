require 'spec_helper'

describe Api::V1::LocationsController, type: :request do
  before(:each) do
    @region = FactoryBot.create(:region, name: 'portland', full_name: 'Portland', lat: 10, lon: 10)
    @another_region = FactoryBot.create(:region, name: 'seattle', full_name: 'Seattle', lat: 20, lon: 20)
    @out_of_bounds_region = FactoryBot.create(:region, name: 'vancouver', full_name: 'Vancouver', lat: 100, lon: 100)
    @location = FactoryBot.create(:location, region: @region, name: 'Satchmo', state: 'OR', zip: '97203', lat: 42.18, lon: -71.18)
    @user = FactoryBot.create(:user, id: 111, username: 'cibw', email: 'foo@bar.com', region: @region, authentication_token: '1G8_s7P-V-4MGojaKD7a')
    @another_region_admin_user = FactoryBot.create(:user, id: 222, username: 'latguy', email: 'lat@guy.com', region: @another_region)
    FactoryBot.create(:user, email: 'super_admin@bar.com', region: nil, is_super_admin: 1)
  end

  describe '#suggest' do
    it 'errors when required fields are not sent' do
      post '/api/v1/locations/suggest.json', params: { region_id: @region.id.to_s, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Location name, and a list of machines are required')

      post '/api/v1/locations/suggest.json', params: { region_id: @region.id.to_s, location_machines: 'foo', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Location name, and a list of machines are required')

      post '/api/v1/locations/suggest.json', params: { region_id: @region.id.to_s, location_name: 'baz', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Location name, and a list of machines are required')

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

    it 'emails admins on new location submission, lets you enter by operator_id and location_type_id and zone_id' do
      lt = FactoryBot.create(:location_type, name: 'type')
      o = FactoryBot.create(:operator, name: 'operator')
      z = FactoryBot.create(:zone, name: 'zone')
      FactoryBot.create(:machine, name: 'Jolene (Pro)', manufacturer: 'Burrito', year: '1995', id: 20)

      expect { post '/api/v1/locations/suggest.json', params: { region_id: @region.id.to_s, location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_phone: 'phone', location_website: 'website', location_type: 'type', location_operator: 'operator', location_zone: 'zone', location_comments: 'comments', location_machines: 'Jolene (Pro) (Burrito, 1995),', submitter_name: 'subname', submitter_email: 'subemail', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' } }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with('AdminMailer', 'send_new_location_notification', 'deliver_now', { params: { to_users: 'admin@pinballmap.com', cc_users: [ 'super_admin@bar.com', 'foo@bar.com' ], subject: 'Pinball Map - New location (Portland) - name', location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_country: nil, location_phone: 'phone', location_website: 'website', location_type: 'type', operator: 'operator', zone: 'zone', location_comments: 'comments', location_machines: 'Jolene (Pro) (Burrito, 1995),', remote_ip: '127.0.0.1', headers: nil, user_agent: nil, user_info: ' by cibw (foo@bar.com)', user_email: 'foo@bar.com' }, args: [] })
    end

    it 'Searches boundary boxes by transmitted lat/lon (geocoded, not user location)' do
      FactoryBot.create(:location_type, name: 'type')
      FactoryBot.create(:machine, name: 'Jolene (Pro)', manufacturer: 'Burrito', year: '1995', id: 20)

      expect { post '/api/v1/locations/suggest.json', params: { region_id: nil, location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_phone: 'phone', location_website: 'website', location_type: 'type', location_operator: nil, location_zone: nil, location_comments: 'comments', location_machines: 'Jolene (Pro) (Burrito, 1995),', submitter_name: 'subname', submitter_email: 'subemail', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', lat: 20, lon: 20 } }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with('AdminMailer', 'send_new_location_notification', 'deliver_now', { params: { to_users: 'admin@pinballmap.com', cc_users: [ 'super_admin@bar.com', 'lat@guy.com' ], subject: 'Pinball Map - New location (Seattle) - name', location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_country: nil, location_phone: 'phone', location_website: 'website', location_type: 'type', operator: '', zone: '', location_comments: 'comments', location_machines: 'Jolene (Pro) (Burrito, 1995),', remote_ip: '127.0.0.1', headers: nil, user_agent: nil, user_info: ' by cibw (foo@bar.com)', user_email: 'foo@bar.com' }, args: [] })
    end

    it 'tags a user when appropriate' do
      FactoryBot.create(:machine, name: 'Jolene (Pro)', manufacturer: 'Burrito', year: '1995', id: 20)
      post '/api/v1/locations/suggest.json', params: { region_id: @region.id.to_s, location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_phone: 'phone', location_website: 'website', location_type: 'type', location_operator: 'operator', location_comments: 'comments', location_machines: 'Jolene (Pro) (Burrito, 1995),', submitter_name: 'subname', submitter_email: 'subemail', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', HTTP_USER_AGENT: 'cleOS' }

      expect(response).to be_successful
      expect(UserSubmission.first.user_id).to eq(111)
    end

    it 'does not bomb out when operator and type and zone are blank' do
      FactoryBot.create(:machine, name: 'Jolene (Pro)', manufacturer: 'Burrito', year: '1995', id: 20)
      post '/api/v1/locations/suggest.json', params: { region_id: @region.id.to_s, location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_phone: 'phone', location_website: 'website', location_type: nil, location_zone: '', location_operator: '', location_comments: 'comments', location_machines: 'Jolene (Pro) (Burrito, 1995),', submitter_name: 'subname', submitter_email: 'subemail', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', HTTP_USER_AGENT: 'cleOS' }

      expect(response).to be_successful
      expect(SuggestedLocation.first.location_type).to eq(nil)
      expect(SuggestedLocation.first.operator).to eq(nil)
      expect(SuggestedLocation.first.zone).to eq(nil)
    end

    it 'does not bomb out if machine list contains string of machine names' do
      post '/api/v1/locations/suggest.json', params: { region_id: @region.id.to_s, location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_phone: 'phone', location_website: 'website', location_type: nil, location_zone: '', location_operator: '', location_comments: 'comments', location_machines: 'Jolene (Pro) (Burrito, 1995), Happy Dog (Premium) (Burrito, 2001),', submitter_name: 'subname', submitter_email: 'subemail', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', HTTP_USER_AGENT: 'cleOS' }

      expect(response).to be_successful
      expect(SuggestedLocation.first.machines).to eq('Jolene (Pro) (Burrito, 1995), Happy Dog (Premium) (Burrito, 2001),')
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

      get '/api/v1/locations.json?by_at_least_n_machines=1'

      expect(JSON.parse(response.body)['errors']).to eq(Api::V1::LocationsController::FILTERING_REQUIRED_MSG)

      get '/api/v1/locations.json?by_at_least_n_machines_type=1'

      expect(JSON.parse(response.body)['errors']).to eq(Api::V1::LocationsController::FILTERING_REQUIRED_MSG)
    end

    it 'forces filters to have a param value' do
      get '/api/v1/locations.json?region='

      expect(JSON.parse(response.body)['errors']).to eq(Api::V1::LocationsController::FILTERING_REQUIRED_MSG)
    end

    it 'respects stern_army filter' do
      FactoryBot.create(:location, region: FactoryBot.create(:region, name: 'la'), name: 'Cleo', is_stern_army: 't')
      FactoryBot.create(:location, region: FactoryBot.create(:region, name: 'chicago'), name: 'Bawb')

      get '/api/v1/locations.json?by_is_stern_army=1'

      expect(response.body).to include('Cleo')
      expect(response.body).to_not include('Bawb')
    end

    it 'respects by_machine_type and by_machine_display filters' do
      region_la = FactoryBot.create(:region, name: 'la', id: 222)

      location = FactoryBot.create(:location, name: 'Cleo', region: region_la)

      FactoryBot.create(:location_machine_xref, location: location, machine: FactoryBot.create(:machine, id: 777, name: 'Cleo Machine', machine_type: 'em', machine_display: 'reels'))

      location2 = FactoryBot.create(:location, name: 'Bawb', region: region_la)

      FactoryBot.create(:location_machine_xref, location: location2, machine: FactoryBot.create(:machine, id: 778, name: 'Bawb Machine', machine_type: 'ss', machine_display: 'dmd'))

      get "/api/v1/region/#{region_la.name}/locations.json?by_machine_type=em"

      expect(response.body).to include('Cleo')
      expect(response.body).to_not include('Bawb')

      get "/api/v1/region/#{region_la.name}/locations.json?by_machine_display=dmd"

      expect(response.body).to_not include('Cleo')
      expect(response.body).to include('Bawb')
    end

    it 'respects with_lmx filter' do
      FactoryBot.create(:location, region: FactoryBot.create(:region, name: 'chicago'), name: 'Bawb')

      lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine, id: 777, name: 'Cleo'))
      FactoryBot.create(:machine_condition, location_machine_xref_id: lmx.id, comment: 'foo bar')

      get "/api/v1/region/#{@region.name}/locations.json", params: { with_lmx: 1 }

      expect(response.body).to include('Satchmo')
      expect(response.body).to include('777')
      expect(response.body).to include('foo bar')
      expect(response.body).to_not include('Bawb')
    end

    it 'disrespects to the combination of regionless_only and with_lmx by not including all lmx' do
      location_type = FactoryBot.create(:location_type)
      FactoryBot.create(:location, region: nil, name: 'Regionless')
      get '/api/v1/locations.json', params: { regionless_only: 1, with_lmx: 1 }

      expect(response.body).to include('Regionless')
      expect(response.body).to_not include('machine_conditions')
    end

    it 'returns all locations in a region within scope without all lmx data' do
      FactoryBot.create(:location, region: FactoryBot.create(:region, name: 'chicago'), name: 'Bawb')

      lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine, id: 777, name: 'Cleo'))
      FactoryBot.create(:machine_condition, location_machine_xref_id: lmx.id, comment: 'foo bar')

      get "/api/v1/region/#{@region.name}/locations.json"

      expect(response.body).to include('Satchmo')
      expect(response.body).to include('777')
      expect(response.body).to_not include('foo bar')
      expect(response.body).to_not include('Bawb')
    end

    it 'respects by_ipdb_id / by_opdb_id filters' do
      lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine, id: 777, name: 'Cleo', ipdb_id: 999, opdb_id: 'b33f'))
      FactoryBot.create(:machine_condition, location_machine_xref_id: lmx.id, comment: 'foo bar')
      get "/api/v1/region/#{@region.name}/locations.json", params: { by_ipdb_id: 999 }

      expect(response.body).to include('Satchmo')
      expect(response.body).to include('777')
      expect(response.body).to_not include('foo bar')

      get "/api/v1/region/#{@region.name}/locations.json", params: { by_opdb_id: 'b33f' }

      expect(response.body).to include('Satchmo')
      expect(response.body).to include('777')
      expect(response.body).to_not include('foo bar')
    end

    it 'respects regionless_only filter' do
      location_type = FactoryBot.create(:location_type)
      FactoryBot.create(:location, region: @region, name: 'Cleo', location_type: location_type)
      FactoryBot.create(:location, region: nil, name: 'Regionless', location_type: location_type)
      get '/api/v1/locations.json', params: { regionless_only: 1, by_type_id: location_type.id }

      expect(response.body).to include('Regionless')
      expect(response.body).to_not include('Cleo')
    end

    it 'respects is_stern_army filter' do
      FactoryBot.create(:location, region: @region, name: 'Stern Army Place', is_stern_army: 't')
      get "/api/v1/region/#{@region.name}/locations.json", params: { by_is_stern_army: 1 }

      expect(response.body).to include('Stern Army Place')
      expect(response.body).to_not include('Satchmo')
    end

    it 'respects ic_active filter' do
      FactoryBot.create(:location, region: @region, name: 'IC Active Place', ic_active: 't')
      get "/api/v1/region/#{@region.name}/locations.json", params: { by_ic_active: true }

      expect(response.body).to include('IC Active Place')
      expect(response.body).to_not include('Satchmo')
    end

    it 'returns username with with_lmx filter' do
      ssw = FactoryBot.create(:user, username: 'ssw')
      lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine, id: 777, name: 'Cleo'), user: ssw)
      FactoryBot.create(:machine_condition, location_machine_xref_id: lmx.id, comment: 'baz', user: ssw)
      get "/api/v1/region/#{@region.name}/locations.json", params: { with_lmx: 1 }

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
      put '/api/v1/locations/' + @location.id.to_s + '.json', params: { phone: 'NOT A PHONE NUMBER', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful

      expect(JSON.parse(response.body)['errors']).to eq([ 'Invalid phone format.' ])

      put '/api/v1/locations/' + @location.id.to_s + '.json', params: { phone: '444-4444', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful

      expect(JSON.parse(response.body)['errors']).to eq([ 'Invalid phone format.' ])

      put '/api/v1/locations/' + @location.id.to_s + '.json', params: { phone: '11-444-4444-11-44', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful

      expect(JSON.parse(response.body)['errors']).to eq([ 'Invalid phone format.' ])
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
      FactoryBot.create(:location_machine_xref, location: closest_location, machine: FactoryBot.create(:machine, name: 'Deleted Pro'), deleted_at: Time.current)

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

    it 'sets a max_distance limit of 500 when no_details is not used' do
      close_location_one = FactoryBot.create(:location, region: @region, lat: 45.49, lon: -122.63)
      close_location_two = FactoryBot.create(:location, region: @region, lat: 45.43627781006716, lon: -109.8149020864871)

      get '/api/v1/locations/closest_by_address.json', params: { address: '97202', send_all_within_distance: 1, max_distance: 800 }

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      locations = parsed_body['locations']
      expect(locations.size).to eq(1)
    end

    it 'sets a max_distance limit of 800 when no_details is used' do
      close_location_one = FactoryBot.create(:location, region: @region, lat: 45.49, lon: -122.63)
      close_location_two = FactoryBot.create(:location, region: @region, lat: 45.43627781006716, lon: -109.8149020864871)

      get '/api/v1/locations/closest_by_address.json', params: { address: '97202', send_all_within_distance: 1, no_details: 1, max_distance: 800 }

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      locations = parsed_body['locations']
      expect(locations.size).to eq(2)
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

    it 'respects by_machine_type and by_machine_display filters and by_machine_year' do
      closest1 = FactoryBot.create(:location, region: @region, name: 'Closest1 Location', street: '123 pine', city: 'portland', state: 'OR', zip: '97202', lat: 45.49, lon: -122.63)

      FactoryBot.create(:location_machine_xref, location: closest1, machine: FactoryBot.create(:machine, name: 'Cleo', manufacturer: 'Stern', machine_type: 'ss', machine_display: 'dmd', year: 2002))

      closest2 = FactoryBot.create(:location, region: @region, name: 'Closest2 Location', street: '123 pine', city: 'portland', state: 'OR', zip: '97202', lat: 45.49, lon: -122.63)

      FactoryBot.create(:location_machine_xref, location: closest2, machine: FactoryBot.create(:machine, name: 'Bawb', manufacturer: 'Stern', machine_type: 'em', machine_display: 'reels', year: 1970))

      get "/api/v1/locations/closest_by_address.json", params: { address: '97202', by_machine_type: 'ss', send_all_within_distance: 1 }

      sleep 1

      parsed_body = JSON.parse(response.body)
      locations = parsed_body['locations']
      expect(locations.size).to eq(1)

      expect(locations[0]['name']).to eq('Closest1 Location')

      get "/api/v1/locations/closest_by_address.json", params: { address: '97202', by_machine_display: 'reels', send_all_within_distance: 1 }

      sleep 1

      parsed_body = JSON.parse(response.body)
      locations = parsed_body['locations']
      expect(locations.size).to eq(1)

      expect(locations[0]['name']).to eq('Closest2 Location')

      get "/api/v1/locations/closest_by_address.json", params: { address: '97202', by_machine_year: '1970', send_all_within_distance: 1 }

      sleep 1

      parsed_body = JSON.parse(response.body)
      locations = parsed_body['locations']
      expect(locations.size).to eq(1)

      expect(locations[0]['name']).to eq('Closest2 Location')
    end

    it 'respects ic_active filter' do
      FactoryBot.create(:location, region: @region, name: 'Cleo', street: '123 pine', city: 'portland', state: 'OR', zip: '97202', lat: 45.49, lon: -122.63, ic_active: 't')

      FactoryBot.create(:location, region: @region, name: 'Bawbn', street: '123 pine', city: 'portland', state: 'OR', zip: '97202', lat: 45.49, lon: -122.63)

      get "/api/v1/locations/closest_by_address.json", params: { address: '97202', by_ic_active: 'true', send_all_within_distance: 1 }

      expect(response.body).to include('Cleo')
      expect(response.body).to_not include('Bawb')
    end

    it 'respects by_machine_id_ic filter' do
      ic_eligible_machine = FactoryBot.create(:machine, id: 777, machine_group_id: 10, ic_eligible: true, name: 'Cleo Machine (Pro)')
      ic_eligible_machine_variant = FactoryBot.create(:machine, id: 778, machine_group_id: 10, ic_eligible: true, name: 'Cleo Machine (Premium)')

      location = FactoryBot.create(:location, region: @region, street: '123 pine', city: 'portland', state: 'OR', zip: '97202', lat: 45.49, lon: -122.63, name: 'Round Tasty Pizza')
      location2 = FactoryBot.create(:location, street: '123 pine', city: 'portland', state: 'OR', zip: '97202', lat: 45.49, lon: -122.63, region: @region, name: 'Slice Time')
      location3 = FactoryBot.create(:location, street: '123 pine', city: 'portland', state: 'OR', zip: '97202', lat: 45.49, lon: -122.63, region: @another_region, name: 'Hut of Pies')

      FactoryBot.create(:location_machine_xref, ic_enabled: true, location: location, machine: ic_eligible_machine)
      FactoryBot.create(:location_machine_xref, ic_enabled: false, location: location2, machine: ic_eligible_machine)
      FactoryBot.create(:location_machine_xref, ic_enabled: true, location: location3, machine: ic_eligible_machine_variant)

      get "/api/v1/locations/closest_by_address.json", params: { address: '97202', by_machine_id_ic: 777, send_all_within_distance: 1 }

      expect(response.body).to include('Round Tasty Pizza')
      expect(response.body).to_not include('Slice Time')
      expect(response.body).to include('Hut of Pies')

      # Guess what, this test should be in another section, but that is ok.
      get "/api/v1/region/#{@region.name}/locations.json", params: { by_machine_id_ic: 777, no_details: 1 }

      expect(response.body).to include('Round Tasty Pizza')
      expect(response.body).to_not include('Slice Time')
      expect(response.body).to_not include('Hut of Pies')
    end

    it 'respects by_machine_single_id_ic filter' do
      ic_eligible_machine = FactoryBot.create(:machine, id: 777, machine_group_id: 10, ic_eligible: true, name: 'Cleo Machine (Pro)')
      ic_eligible_machine_variant = FactoryBot.create(:machine, id: 778, machine_group_id: 10, ic_eligible: true, name: 'Cleo Machine (Premium)')

      location = FactoryBot.create(:location, street: '123 pine', city: 'portland', state: 'OR', zip: '97202', lat: 45.49, lon: -122.63, name: 'Round Tasty Pizza')
      location2 = FactoryBot.create(:location, street: '123 pine', city: 'portland', state: 'OR', zip: '97202', lat: 45.49, lon: -122.63, name: 'Hut of Pies')

      FactoryBot.create(:location_machine_xref, ic_enabled: true, location: location, machine: ic_eligible_machine)
      FactoryBot.create(:location_machine_xref, ic_enabled: true, location: location2, machine: ic_eligible_machine_variant)

      get "/api/v1/locations/closest_by_address.json", params: { address: '97202', by_machine_single_id_ic: 777, send_all_within_distance: 1 }

      expect(response.body).to include('Round Tasty Pizza')
      expect(response.body).to_not include('Hut of Pies')
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
      expect(location['machine_ids']).to eq([ 201, 200, 202 ])
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

    it 'sets a max_distance limit of 500 when no_details is not used' do
      close_location_one = FactoryBot.create(:location, region: @region, lat: 45.49, lon: -122.63)
      close_location_two = FactoryBot.create(:location, region: @region, lat: 45.43627781006716, lon: -109.8149020864871)

      get '/api/v1/locations/closest_by_address.json', params: { address: '97202', send_all_within_distance: 1, max_distance: 800 }

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      locations = parsed_body['locations']
      expect(locations.size).to eq(1)
    end

    it 'sets a max_distance limit of 800 when no_details is used' do
      close_location_one = FactoryBot.create(:location, region: @region, lat: 45.49, lon: -122.63)
      close_location_two = FactoryBot.create(:location, region: @region, lat: 45.43627781006716, lon: -109.8149020864871)

      get '/api/v1/locations/closest_by_address.json', params: { address: '97202', send_all_within_distance: 1, no_details: 1, max_distance: 800 }

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      locations = parsed_body['locations']
      expect(locations.size).to eq(2)
    end

    it 'respects filters' do
      location_type = FactoryBot.create(:location_type)
      machine = FactoryBot.create(:machine, machine_type: 'ss', machine_display: 'dmd')
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

      get '/api/v1/locations/closest_by_lat_lon.json', params: { lat: close_location_one.lat, lon: close_location_one.lon, by_machine_type: 'ss', send_all_within_distance: 1 }

      locations = JSON.parse(response.body)['locations']
      expect(locations.size).to eq(1)
      expect(locations[0]['id']).to eq(close_location_two.id)

      get '/api/v1/locations/closest_by_lat_lon.json', params: { lat: close_location_one.lat, lon: close_location_one.lon, by_machine_display: 'dmd', send_all_within_distance: 1 }

      locations = JSON.parse(response.body)['locations']
      expect(locations.size).to eq(1)
      expect(locations[0]['id']).to eq(close_location_two.id)
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

  describe '#within_bounding_box' do
    it 'sends you locations within the transmitted bounding box, along with machines at the locations' do
      get '/api/v1/locations/within_bounding_box.json', params: { swlat: 45.49035574474385, swlon: -122.63006168000643, nelat: 45.50337485147459, nelon: -122.61434785688468 }

      expect(JSON.parse(response.body)['errors']).to eq('No locations found within bounding box.')

      close_location_one = FactoryBot.create(:location, name: 'Close_1', region: @region, lat: 45.526112069408704, lon: -122.60884314086321, location_type_id: 1, operator_id: 1)
      close_location_two = FactoryBot.create(:location, name: 'Close_2', region: @region, lat: 45.53007190362438, lon: -122.60795065851514, location_type_id: 2, operator_id: 2)
      close_location_three = FactoryBot.create(:location, name: 'Close_3', region: @region, lat: 45.53007190362438, lon: -122.60795065851514, location_type_id: 3, operator_id: 3)
      FactoryBot.create(:location, name: 'Far_Bar', region: @region, lat: 46.491, lon: -122.63)
      FactoryBot.create(:location, region: @region, lat: 5.49, lon: 22.63)
      machine_group = FactoryBot.create(:machine_group, id: 1001, name: 'Sass')
      machine = FactoryBot.create(:machine)
      machine_two = FactoryBot.create(:machine, machine_group_id: 1001)
      machine_three = FactoryBot.create(:machine, machine_group_id: 1001)
      FactoryBot.create(:location_machine_xref, location: close_location_one, machine_id: machine.id)
      FactoryBot.create(:location_machine_xref, location: close_location_two, machine_id: machine_two.id)
      FactoryBot.create(:location_machine_xref, location: close_location_two, machine_id: machine_three.id)

      FactoryBot.create(:user_fave_location, user: @user, location: close_location_one)

      get '/api/v1/locations/within_bounding_box.json', params: { swlat: 45.478363717877436, swlon: -122.64672405963799, nelat: 45.54521396088108, nelon: -122.56878059990427 }

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      locations = parsed_body['locations']
      expect(response.body).to_not include('Far_Bar')
      expect(response.body).to include('Close_1')
      expect(response.body).to include('Close_2')

      get '/api/v1/locations/within_bounding_box.json', params: { swlat: 45.478363717877436, swlon: -122.64672405963799, nelat: 45.54521396088108, nelon: -122.56878059990427, by_type_id: 1 }

      expect(response.body).to include('Close_1')
      expect(response.body).to_not include('Close_2')

      FactoryBot.create(:location_machine_xref, location: close_location_three, machine_id: machine_three.id)
      get '/api/v1/locations/within_bounding_box.json', params: { swlat: 45.478363717877436, swlon: -122.64672405963799, nelat: 45.54521396088108, nelon: -122.56878059990427, by_machine_id: machine_two.id }

      expect(response.body).to_not include('Close_1')
      expect(response.body).to include('Close_2')
      expect(response.body.scan('Close_2').size).to eq(1)

      get '/api/v1/locations/within_bounding_box.json', params: { swlat: 45.478363717877436, swlon: -122.64672405963799, nelat: 45.54521396088108, nelon: -122.56878059990427, by_machine_id: "#{machine_two.id}_#{machine_three.id}" }

      expect(response.body).to_not include('Close_1')
      expect(response.body).to include('Close_2')
      expect(response.body).to include('Close_3')

      get '/api/v1/locations/within_bounding_box.json', params: { swlat: 45.478363717877436, swlon: -122.64672405963799, nelat: 45.54521396088108, nelon: -122.56878059990427, by_machine_group_id: 1001 }

      expect(response.body).to_not include('Close_1')
      expect(response.body).to include('Close_2')
      expect(response.body).to include('Close_3')

      get '/api/v1/locations/within_bounding_box.json', params: { swlat: 45.478363717877436, swlon: -122.64672405963799, nelat: 45.54521396088108, nelon: -122.56878059990427, by_machine_single_id: machine_two.id }

      expect(response.body).to_not include('Close_1')
      expect(response.body).to include('Close_2')
      expect(response.body).to_not include('Close_3')

      get '/api/v1/locations/within_bounding_box.json', params: { swlat: 45.478363717877436, swlon: -122.64672405963799, nelat: 45.54521396088108, nelon: -122.56878059990427, by_operator_id: 1 }

      expect(response.body).to include('Close_1')
      expect(response.body).to_not include('Close_2')

      get '/api/v1/locations/within_bounding_box.json', params: { swlat: 45.478363717877436, swlon: -122.64672405963799, nelat: 45.54521396088108, nelon: -122.56878059990427, by_at_least_n_machines_type: 2 }

      expect(response.body).to_not include('Close_1')
      expect(response.body).to include('Close_2')

      get '/api/v1/locations/within_bounding_box.json', params: { swlat: 45.478363717877436, swlon: -122.64672405963799, nelat: 45.54521396088108, nelon: -122.56878059990427, user_faved: @user.id }

      expect(response.body).to include('Close_1')
      expect(response.body).to_not include('Close_2')

      get '/api/v1/locations/within_bounding_box.geojson', params: { swlat: 45.478363717877436, swlon: -122.64672405963799, nelat: 45.54521396088108, nelon: -122.56878059990427 }

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(2)

      locations = parsed_body['locations']
      expect(response.body).to include('FeatureCollection')
      expect(response.body).to include('Point')
    end

    it 'respects no_details and shows fewer location fields' do
      close_location_one = FactoryBot.create(:location, id: 5555, street: '123 Main St', name: 'Close_1', phone: '111-222-3333', website: 'https://website.gov', region: @region, lat: 45.526112069408704, lon: -122.60884314086321, location_type_id: 1, operator_id: 1)
      machine = FactoryBot.create(:machine)
      FactoryBot.create(:location_machine_xref, location: close_location_one, machine_id: machine.id)

      get '/api/v1/locations/within_bounding_box.json', params: { swlat: 45.478363717877436, swlon: -122.64672405963799, nelat: 45.54521396088108, nelon: -122.56878059990427, no_details: 1 }

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      locations = parsed_body['locations']
      expect(response.body).to include('Close_1')
      expect(response.body).to include('5555')
      expect(response.body).to include('45.5261120')
      expect(response.body).to include('-122.608843')
      expect(response.body).to include('123 Main St')
      expect(response.body).to_not include('111-222-3333')
      expect(response.body).to_not include('https://website.gov')

      get '/api/v1/locations/within_bounding_box.json', params: { swlat: 45.478363717877436, swlon: -122.64672405963799, nelat: 45.54521396088108, nelon: -122.56878059990427, no_details: 2 }

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      locations = parsed_body['locations']
      expect(response.body).to include('Close_1')
      expect(response.body).to include('5555')
      expect(response.body).to include('45.5261120')
      expect(response.body).to include('-122.608843')
      expect(response.body).to_not include('123 Main St')
      expect(response.body).to_not include('111-222-3333')
      expect(response.body).to_not include('https://website.gov')
    end

    it 'limits results when limit param is present and includes pagy metadata' do
      FactoryBot.create(:location, name: 'Close_1', id: 8000, lat: 45.526112069408704, lon: -122.60884314086321)
      FactoryBot.create(:location, name: 'Close_2', id: 7000, lat: 45.53007190362438, lon: -122.60795065851514)
      FactoryBot.create(:location, name: 'Close_3', id: 6000, lat: 45.53007190362438, lon: -122.60795065851514)

      get '/api/v1/locations/within_bounding_box.json', params: { swlat: 45.478363717877436, swlon: -122.64672405963799, nelat: 45.54521396088108, nelon: -122.56878059990427, limit: 2 }

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(2)

      locations = parsed_body['locations']
      expect(response.body).to include('Close_1')
      expect(response.body).to include('Close_2')
      expect(response.body).to_not include('Close_3')
      expect(response.body).to include('pagy')
    end

    it 'orders results when order_by param is present' do
      location_01 = FactoryBot.create(:location, name: 'A_Location', id: 6000, lat: 45.526112069408704, lon: -122.60884314086321)
      location_02 = FactoryBot.create(:location, name: 'B_Location', id: 7000, lat: 45.53007190362438, lon: -122.60795065851514)
      location_03 = FactoryBot.create(:location, name: 'C_Location', id: 8000, lat: 45.53007190362438, lon: -122.60795065851514)

      machine = FactoryBot.create(:machine)
      machine_two = FactoryBot.create(:machine)
      machine_three = FactoryBot.create(:machine)

      FactoryBot.create(:location_machine_xref, location: location_01, machine_id: machine.id)

      FactoryBot.create(:location_machine_xref, location: location_03, machine_id: machine.id)
      FactoryBot.create(:location_machine_xref, location: location_03, machine_id: machine_two.id)
      FactoryBot.create(:location_machine_xref, location: location_03, machine_id: machine_three.id)

      FactoryBot.create(:location_machine_xref, location: location_02, machine_id: machine.id)
      FactoryBot.create(:location_machine_xref, location: location_02, machine_id: machine_two.id)

      get '/api/v1/locations/within_bounding_box.json', params: { swlat: 45.478363717877436, swlon: -122.64672405963799, nelat: 45.54521396088108, nelon: -122.56878059990427 }

      parsed_body = JSON.parse(response.body)
      locations = parsed_body['locations']
      expect(locations.size).to eq(3)

      expect(locations[0]['name']).to eq('C_Location')
      expect(locations[1]['name']).to eq('B_Location')
      expect(locations[2]['name']).to eq('A_Location')

      get '/api/v1/locations/within_bounding_box.json', params: { swlat: 45.478363717877436, swlon: -122.64672405963799, nelat: 45.54521396088108, nelon: -122.56878059990427, order_by: 'name' }

      parsed_body = JSON.parse(response.body)
      locations = parsed_body['locations']
      expect(locations.size).to eq(3)

      expect(locations[0]['name']).to eq('A_Location')
      expect(locations[1]['name']).to eq('B_Location')
      expect(locations[2]['name']).to eq('C_Location')

      get '/api/v1/locations/within_bounding_box.json', params: { swlat: 45.478363717877436, swlon: -122.64672405963799, nelat: 45.54521396088108, nelon: -122.56878059990427, order_by: 'machine_count' }

      parsed_body = JSON.parse(response.body)
      locations = parsed_body['locations']
      expect(locations.size).to eq(3)

      expect(locations[0]['name']).to eq('C_Location')
      expect(locations[1]['name']).to eq('B_Location')
      expect(locations[2]['name']).to eq('A_Location')

      get '/api/v1/locations/within_bounding_box.json', params: { swlat: 45.478363717877436, swlon: -122.64672405963799, nelat: 45.54521396088108, nelon: -122.56878059990427, order_by: 'updated_at' }

      parsed_body = JSON.parse(response.body)
      locations = parsed_body['locations']
      expect(locations.size).to eq(3)

      expect(locations[0]['name']).to eq('B_Location')
      expect(locations[1]['name']).to eq('C_Location')
      expect(locations[2]['name']).to eq('A_Location')
    end
  end

  describe '#picture_details' do
    before(:each) do
      Aws.config[:s3] = { stub_responses: true }
    end
    it 'throws an error if the location does not exist' do
      get '/api/v1/locations/666/picture_details.json'

      expect(JSON.parse(response.body)['errors']).to eq('Failed to find location')
    end

    it 'displays details of pictures at location' do
      post '/api/v1/location_picture_xrefs.json', params: { location_id: @location.id.to_s, photo: fixture_file_upload('PPM-Splash-200.png', 'image/png'), user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', format: :js }

      expect(response).to be_successful
      expect(response.body).to include('location_picture')

      get '/api/v1/locations/' + @location.id.to_s + '/picture_details.json'
      expect(response).to be_successful

      pictures = JSON.parse(response.body)['pictures']

      expect(pictures[0]['url']).not_to be_nil
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
      FactoryBot.create(:location_machine_xref, deleted_at: Time.current, location: @location, machine: FactoryBot.create(:machine, id: 234, name: 'Deleted Pro', year: 1960, manufacturer: 'Bally', ipdb_link: 'http://www.bar.com', ipdb_id: 234))
      get '/api/v1/locations/' + @location.id.to_s + '/machine_details.json'
      expect(response).to be_successful

      machines = JSON.parse(response.body)['machines']

      expect(machines.size).to eq(2)

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

    it 'respects the machines_only flag' do
      FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine, id: 123, name: 'Cleo', year: 1980, manufacturer: 'Stern', ipdb_link: 'http://www.foo.com', ipdb_id: nil))
      FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine, id: 456, name: 'Sass', year: 1960, manufacturer: 'Bally', ipdb_link: 'http://www.bar.com', ipdb_id: 123))
      get '/api/v1/locations/' + @location.id.to_s + '/machine_details.json', params: { machines_only: 1 }
      expect(response).to be_successful

      machines = JSON.parse(response.body)['machines']
      expect(machines[0]).to eq('Cleo (Stern, 1980)')
      expect(machines[1]).to eq('Sass (Bally, 1960)')
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
    before(:each) do
      lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine, id: 7777, name: 'Cleo'))
      FactoryBot.create(:machine_condition, location_machine_xref_id: lmx.id, comment: 'foo bar')
      FactoryBot.create(:machine_score_xref, location_machine_xref: lmx, score: 567_890)
      FactoryBot.create(:location_machine_xref, deleted_at: Time.current, location: @location, machine: FactoryBot.create(:machine, id: 8888, name: 'Deleted Pro'))
    end

    it 'returns all locations within region scope along with lmx data' do
      get "/api/v1/region/#{@region.name}/locations/#{@location.id}.json"

      expect(response.body).to include('Satchmo')
      expect(response.body).to include('777')
      expect(response.body).to include('foo bar')
      expect(response.body).to include('567')
    end

    it 'show location info plus comments and scores' do
      get "/api/v1/locations/#{@location.id}.json"

      expect(response.body).to include('Satchmo')
      expect(response.body).to include('7777')
      expect(response.body).to include('foo bar')
      expect(response.body).to include('567890')
    end

    it 'respects no_details and shows fewer location fields' do
      get "/api/v1/locations/#{@location.id}.json", params: { no_details: 1 }

      expect(response.body).to include('Satchmo')
      expect(response.body).to include('7777')
      expect(response.body).to_not include('foo bar')
      expect(response.body).to_not include('567890')

      get "/api/v1/locations/#{@location.id}.json", params: { no_details: 2 }

      expect(response.body).to include('Satchmo')
      expect(response.body).to include('Cleo')
      expect(response.body).to_not include('Deleted Pro')
      expect(response.body).to_not include('7777')
      expect(response.body).to_not include('foo bar')
      expect(response.body).to_not include('567890')
    end
  end

  describe '#top_cities' do
    it 'returns a count of locations for cities' do
      FactoryBot.create(:location, city: 'Los Angeles', state: 'CA')
      FactoryBot.create(:location, city: 'Los Angeles', state: 'CA')
      FactoryBot.create(:location, city: 'Portland', state: 'OR')
      FactoryBot.create(:location, city: 'Portland', state: 'OR')
      FactoryBot.create(:location, city: 'Portland', state: 'OR')
      FactoryBot.create(:location, city: 'Seattle', state: 'WA')
      get '/api/v1/locations/top_cities.json'

      portland = JSON.parse(response.body)[0]
      expect(portland['location_count']).to eq(4)
      expect(portland['city']).to eq('Portland')
      la = JSON.parse(response.body)[1]
      expect(la['location_count']).to eq(2)
      expect(la['city']).to eq('Los Angeles')
      seattle = JSON.parse(response.body)[2]
      expect(seattle['location_count']).to eq(1)
      expect(seattle['city']).to eq('Seattle')
    end
  end

  describe '#top_cities_by_machine' do
    it 'returns a count of number of machines by cities' do
      portland_location = FactoryBot.create(:location, city: 'Portland', state: 'OR')
      seattle_location = FactoryBot.create(:location, city: 'Seattle', state: 'WA')
      FactoryBot.create(:location_machine_xref, location: portland_location, machine: FactoryBot.create(:machine, id: 200, name: 'Cleo'))
      FactoryBot.create(:location_machine_xref, location: portland_location, machine: FactoryBot.create(:machine, id: 201, name: 'Bawb'))
      FactoryBot.create(:location_machine_xref, location: seattle_location, machine: FactoryBot.create(:machine, id: 202, name: 'Sassy'))
      get '/api/v1/locations/top_cities_by_machine.json'

      portland = JSON.parse(response.body)[0]
      expect(portland['machines_count']).to eq(2)
      expect(portland['city']).to eq('Portland')
      seattle = JSON.parse(response.body)[1]
      expect(seattle['machines_count']).to eq(1)
      expect(seattle['city']).to eq('Seattle')
    end
  end

  describe '#type_count' do
    it 'returns a count of location types' do
      lt = FactoryBot.create(:location_type, name: 'type')
      lt2 = FactoryBot.create(:location_type, name: 'type2')
      FactoryBot.create(:location, location_type: lt)
      FactoryBot.create(:location, location_type: lt)
      FactoryBot.create(:location, location_type: lt)
      FactoryBot.create(:location, location_type: lt2)
      FactoryBot.create(:location, location_type: lt2)

      get '/api/v1/locations/type_count.json'

      type = JSON.parse(response.body)[0]
      expect(type['type_count']).to eq(3)
      expect(type['name']).to eq('type')
      type2 = JSON.parse(response.body)[1]
      expect(type2['type_count']).to eq(2)
      expect(type2['name']).to eq('type2')
    end
  end

  describe '#countries' do
    it 'returns a count of number of locations by countries' do
      FactoryBot.create(:location, city: 'Portland', state: 'OR', country: 'US')
      FactoryBot.create(:location, city: 'Portland', state: 'OR', country: 'US')
      FactoryBot.create(:location, city: 'Toronto', state: 'ON', country: 'CA')

      get '/api/v1/locations/countries.json'

      US = JSON.parse(response.body)[0]
      expect(US['location_count']).to eq(3)
      CA = JSON.parse(response.body)[1]
      expect(CA['location_count']).to eq(1)
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
    end

    it 'should return an empty array if no found results' do
      FactoryBot.create(:location, city: 'Portland', state: 'ME')
      FactoryBot.create(:location, city: 'Portland', state: 'OR')
      FactoryBot.create(:location, city: 'Beaverton')

      get '/api/v1/locations/autocomplete_city', params: { name: 'asdf' }

      expect(response.body).to eq('[]')
    end

    it 'should return an empty array if below minimum character threshold' do
      FactoryBot.create(:location, city: 'Portland', state: 'ME')
      FactoryBot.create(:location, city: 'Portland', state: 'OR')
      FactoryBot.create(:location, city: 'Beaverton')

      get '/api/v1/locations/autocomplete_city', params: { name: 'df' }

      expect(response.body).to eq('[]')
    end
  end

  describe '#autocomplete' do
    it 'should do a fuzzy search on name and return a list of in-scope names and IDs' do
      FactoryBot.create(:location, name: 'foo')
      bar = FactoryBot.create(:location, name: 'bar')
      barfoo = FactoryBot.create(:location, name: 'barfoo')

      get '/api/v1/locations/autocomplete', params: { name: 'bar' }

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

    it 'should return an empty array if below minimum character threshold' do
      FactoryBot.create(:location, name: 'foo')
      FactoryBot.create(:location, name: 'bar')
      FactoryBot.create(:location, name: 'barfoo')

      get '/api/v1/locations/autocomplete', params: { name: 'as' }

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
