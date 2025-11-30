require 'spec_helper'

describe Api::V1::LocationMachineXrefsController, type: :request do
  before(:each) do
    @region = FactoryBot.create(:region, id: 3, name: 'portland', should_email_machine_removal: 0)
    @location = FactoryBot.create(:location, id: 1, name: 'Ground Kontrol', region: @region)
    @machine = FactoryBot.create(:machine, id: 2, name: 'Cleo')

    @lmx = FactoryBot.create(:location_machine_xref, machine_id: @machine.id, location_id: @location.id)

    FactoryBot.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw')
  end

  describe '#delete' do
    it 'soft-deletes an lmx' do
      delete '/api/v1/location_machine_xrefs/' + @lmx.id.to_s + '.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(response.status).to eq(200)

      expect(JSON.parse(response.body)['msg']).to eq('Successfully deleted lmx #' + @lmx.id.to_s)
      expect(LocationMachineXref.where(deleted_at: nil).all.size).to eq(0)
      expect(LocationMachineXref.unscoped.where.not(deleted_at: nil).all.size).to eq(1)
    end

    it 'creates a user submission for the deletion' do
      delete '/api/v1/location_machine_xrefs/' + @lmx.id.to_s + '.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }, headers: { HTTP_USER_AGENT: 'cleOS' }
      expect(response).to be_successful

      expect(JSON.parse(response.body)['msg']).to eq('Successfully deleted lmx #' + @lmx.id.to_s)

      submission = Region.find(@lmx.location.region_id).user_submissions.second
      expect(submission.submission_type).to eq(UserSubmission::REMOVE_MACHINE_TYPE)
      expect(submission.submission).to eq('Cleo was removed from Ground Kontrol in Portland by ssw')
      expect(submission.user_id).to eq(111)
    end

    it 'errors if lmx id does not exist' do
      delete '/api/v1/location_machine_xrefs/-1.json'
      expect(response).to be_successful

      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine')
      expect(LocationMachineXref.all.size).to eq(1)
    end

    it 'errors if not authed' do
      delete '/api/v1/location_machine_xrefs/' + @lmx.id.to_s + '.json'
      expect(response).to be_successful

      expect(JSON.parse(response.body)['errors']).to eq(Api::V1::LocationMachineXrefsController::AUTH_REQUIRED_MSG)
      expect(LocationMachineXref.all.size).to eq(1)
    end
  end

  describe '#index' do
    it 'sends all lmxes in region and excludes soft-deleted lmxes' do
      chicago = FactoryBot.create(:region, id: 11, name: 'chicago')
      FactoryBot.create(:location_machine_xref, machine: @machine, location: FactoryBot.create(:location, id: 11, name: 'Chicago Location', region: chicago))
      machine2 = FactoryBot.create(:machine, id: 3, name: 'Sass')

      FactoryBot.create(:location_machine_xref, machine: machine2, deleted_at: Time.current, location: FactoryBot.create(:location, id: 12, name: 'Chicago Location 2', region: chicago))

      get '/api/v1/region/portland/location_machine_xrefs.json'
      expect(response).to be_successful

      lmxes = JSON.parse(response.body)['location_machine_xrefs']

      expect(lmxes.size).to eq(1)

      expect(lmxes[0]['location_id']).to eq(@location.id)
      expect(lmxes[0]['machine_id']).to eq(@machine.id)
    end

    it "only sends the #{MachineCondition::MAX_HISTORY_SIZE_TO_DISPLAY} most recent machine_conditions" do
      chicago = FactoryBot.create(:region, name: 'chicago')
      lmx = FactoryBot.create(:location_machine_xref, machine: @machine, location: FactoryBot.create(:location, id: 12, name: 'Chicago Location', region: chicago))

      (MachineCondition::MAX_HISTORY_SIZE_TO_DISPLAY + 10).times do
        FactoryBot.create(:machine_condition, location_machine_xref: lmx.reload, comment: 'Foo')
      end

      get '/api/v1/region/chicago/location_machine_xrefs.json'
      expect(response).to be_successful

      lmxes = JSON.parse(response.body)['location_machine_xrefs']

      expect(lmxes[0]['machine_conditions'].size).to eq(MachineCondition::MAX_HISTORY_SIZE_TO_DISPLAY)
    end

    it 'respects limit scope' do
      newest_lmx = FactoryBot.create(:location_machine_xref, machine: FactoryBot.create(:machine, name: 'Barb'), location: @location)

      get '/api/v1/region/portland/location_machine_xrefs.json?limit=1'
      expect(response).to be_successful

      expect(JSON.parse(response.body)['location_machine_xrefs'].size).to eq(1)
      expect(JSON.parse(response.body)['location_machine_xrefs'][0]['id']).to eq(newest_lmx.id)
    end
  end

  describe '#create' do
    it 'updates condition on existing lmx' do
      post '/api/v1/location_machine_xrefs.json', params: { machine_id: @machine.id.to_s, location_id: @location.id.to_s, condition: 'foo', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(LocationMachineXref.all.size).to eq(1)
    end

    it 'updates condition on existing lmx - authed' do
      post '/api/v1/location_machine_xrefs.json', params: { machine_id: @machine.id.to_s, location_id: @location.id.to_s, condition: 'foo', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful

      updated_lmx = @lmx.reload
      expect(updated_lmx.location.last_updated_by_user.id).to eq(111)
      expect(LocationMachineXref.all.size).to eq(1)
    end

    it 'creates new lmx when appropriate' do
      new_machine = FactoryBot.create(:machine, id: 11, name: 'sass')

      post '/api/v1/location_machine_xrefs.json', params: { machine_id: new_machine.id.to_s, location_id: @location.id.to_s, condition: 'foo', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(response.status).to eq(201)

      expect(LocationMachineXref.all.size).to eq(2)
    end

    it "doesn't let you add machines that don't exist" do
      post '/api/v1/location_machine_xrefs.json', params: { machine_id: -666, location_id: @location.id.to_s, condition: 'foo', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine')

      expect(LocationMachineXref.all.size).to eq(1)
    end

    it 'does not let you add two of the same machine' do
    end

    it 're-adds a soft-deleted lmx if removed within 7 days and includes scores and conditions' do
      FactoryBot.create(:machine_condition, location_machine_xref: @lmx, comment: 'plays soft')
      FactoryBot.create(:machine_score_xref, location_machine_xref: @lmx, score: 998899)

      delete '/api/v1/location_machine_xrefs/' + @lmx.id.to_s + '.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(response.status).to eq(200)

      get '/api/v1/location_machine_xrefs/' + @lmx.id.to_s + '.json'
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine')

      expect(LocationMachineXref.all.size).to eq(0)

      post '/api/v1/location_machine_xrefs.json', params: { machine_id: @machine.id.to_s, location_id: @location.id.to_s, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      expect(response.status).to eq(200)

      expect(LocationMachineXref.all.size).to eq(1)

      get '/api/v1/location_machine_xrefs/' + @lmx.id.to_s + '.json'
      expect(response).to be_successful

      lmx = JSON.parse(response.body)['location_machine']
      machine_conditions = lmx['machine_conditions']

      expect(machine_conditions.size).to eq(1)
      expect(machine_conditions[0]['comment']).to eq('plays soft')
      expect(lmx['machine_score_xrefs'].size).to eq(1)
      expect(lmx['machine_score_xrefs'][0]['score']).to eq(998899)
    end

    it 'does not re-add soft-deleted lmx if removed more than 7 days ago' do
      FactoryBot.create(:machine_condition, location_machine_xref: @lmx, comment: 'plays soft')
      FactoryBot.create(:machine_score_xref, location_machine_xref: @lmx, score: 998899)

      delete '/api/v1/location_machine_xrefs/' + @lmx.id.to_s + '.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(response.status).to eq(200)

      get '/api/v1/location_machine_xrefs/' + @lmx.id.to_s + '.json'
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine')

      @lmx.deleted_at = Time.current - 20.days
      @lmx.save

      expect(LocationMachineXref.all.size).to eq(0)

      post '/api/v1/location_machine_xrefs.json', params: { machine_id: @machine.id.to_s, location_id: @location.id.to_s, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      expect(response.status).to eq(201)

      expect(LocationMachineXref.all.size).to eq(1)

      get '/api/v1/location_machine_xrefs/' + LocationMachineXref.all.last.id.to_s + '.json'
      expect(response).to be_successful

      lmx = JSON.parse(response.body)['location_machine']

      expect(lmx['machine_conditions']).to be_empty
      expect(lmx['machine_score_xrefs']).to be_empty
    end

    it 'does not create a machine condition if you pass a blank condition' do
      new_machine = FactoryBot.create(:machine, id: 22, name: 'sass')

      post '/api/v1/location_machine_xrefs.json', params: { machine_id: new_machine.id.to_s, location_id: @location.id.to_s, condition: '', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(response.status).to eq(201)

      expect(MachineCondition.all.size).to eq(0)
    end

    it 'returns an error unless the machine_id and location_id are both present' do
      post '/api/v1/location_machine_xrefs.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine')

      post '/api/v1/location_machine_xrefs.json', params: { machine_id: @machine.id.to_s, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine')

      post '/api/v1/location_machine_xrefs.json', params: { location_id: @location.id.to_s, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine')
    end

    it 'returns an error if you are not authenticated' do
      post '/api/v1/location_machine_xrefs.json', params: { machine_id: 123, location_id: @location.id.to_s, condition: 'foo' }
      expect(response).to be_successful

      expect(JSON.parse(response.body)['errors']).to eq(Api::V1::LocationMachineXrefsController::AUTH_REQUIRED_MSG)
    end
  end

  describe '#update' do
    before(:each) do
      @region = FactoryBot.create(:region, id: 22, name: 'Portland')
      @location = FactoryBot.create(:location, id: 3, name: 'Ground Kontrol', region: @region)
      @machine = FactoryBot.create(:machine, id: 4, name: 'Cleo')

      @lmx = FactoryBot.create(:location_machine_xref, machine_id: @machine.id, location_id: @location.id)
    end

    it 'updates condition' do
      FactoryBot.create(:machine_condition, location_machine_xref: @lmx, comment: 'bar')

      put '/api/v1/location_machine_xrefs/' + @lmx.id.to_s, params: { condition: 'foo', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', HTTP_USER_AGENT: 'cleOS' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)['location_machine']['machine_conditions'][0]['comment']).to eq('foo')
      expect(JSON.parse(response.body)['location_machine']['machine_conditions'][0]['username']).to eq('ssw')
      expect(JSON.parse(response.body)['location_machine']['machine_conditions'][1]['comment']).to eq('bar')
      expect(JSON.parse(response.body)['location_machine']['machine_conditions'][1]['username']).to eq('')

      @lmx.reload
      expect(@lmx.location.last_updated_by_user.id).to eq(111)
    end

    it 'returns an error message if the lmx does not exist' do
      put '/api/v1/location_machine_xrefs/666?condition=foo'
      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine')
    end

    it 'returns an error message if you are not authed' do
      put '/api/v1/location_machine_xrefs/' + @lmx.id.to_s, params: { condition: 'foo', HTTP_HOST: 'pbmstaging.com' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq(Api::V1::LocationMachineXrefsController::AUTH_REQUIRED_MSG)
    end
  end

  describe '#get' do
    it 'sends all detail about this lmx (including machine conditions and scores)' do
      chicago = FactoryBot.create(:region, id: 11, name: 'chicago')
      lmx = FactoryBot.create(:location_machine_xref, id: 100, machine: @machine, location: FactoryBot.create(:location, id: 11, name: 'Chicago Location', region: chicago))
      FactoryBot.create(:machine_condition, id: 1, location_machine_xref: lmx.reload, comment: 'foo')
      FactoryBot.create(:machine_condition, id: 2, location_machine_xref: lmx.reload, comment: 'bar')
      FactoryBot.create(:machine_score_xref, id: 2, location_machine_xref: lmx.reload, score: 321123)

      get '/api/v1/location_machine_xrefs/' + lmx.id.to_s + '.json'
      expect(response).to be_successful

      lmx = JSON.parse(response.body)['location_machine']
      machine_conditions = lmx['machine_conditions']

      expect(machine_conditions.size).to eq(2)
      expect(machine_conditions[0]['comment']).to eq('bar')
      expect(machine_conditions[1]['comment']).to eq('foo')
      expect(lmx['machine_score_xrefs'].size).to eq(1)
      expect(lmx['machine_score_xrefs'][0]['score']).to eq(321123)
    end
  end

  describe '#top_n_machines' do
    it 'sends back the top N machines' do
      chicago = FactoryBot.create(:region)

      first_machine = FactoryBot.create(:machine, id: 1111, name: 'machine 1 (LE)', opdb_id: 'b33fy-ch33s')
      second_machine = FactoryBot.create(:machine, id: 2222, name: 'machine 1 (Pro)', opdb_id: 'b33fy-t2cos')
      third_machine = FactoryBot.create(:machine, id: 3333, name: 'machine 2', opdb_id: 'ch33s')
      fourth_machine = FactoryBot.create(:machine, id: 4444, name: 'machine 3', opdb_id: 'gr@vy')

      2.times do |index|
        FactoryBot.create(:location_machine_xref, machine: first_machine, location: FactoryBot.create(:location, id: 111 + index, region: chicago))
      end

      2.times do |index|
        FactoryBot.create(:location_machine_xref, machine: second_machine, location: FactoryBot.create(:location, id: 222 + index, region: chicago))
        FactoryBot.create(:location_machine_xref, machine: third_machine, location: FactoryBot.create(:location, id: 333 + index, region: chicago))
      end

      FactoryBot.create(:location_machine_xref, machine: fourth_machine, location: FactoryBot.create(:location, id: 444, region: chicago))

      get '/api/v1/location_machine_xrefs/top_n_machines.json?n=2'
      expect(response).to be_successful

      machines = JSON.parse(response.body)['machines']
      expect(machines.size).to eq(2)

      expect(machines[0]['machine_name']).to eq('machine 1')
      expect(machines[1]['machine_name']).to eq('machine 2')
    end

    it 'defaults to top 25' do
      ActiveRecord::Base.connection.tables.each do |t|
        ActiveRecord::Base.connection.reset_pk_sequence!(t)
      end

      30.times do |index|
        FactoryBot.create(:location_machine_xref, machine: FactoryBot.create(:machine, id: 1111 + index, name: 'machine ' + index.to_s, opdb_id: 'b33' + index.to_s), location: FactoryBot.create(:location))
      end

      get '/api/v1/location_machine_xrefs/top_n_machines.json'
      expect(response).to be_successful

      machines = JSON.parse(response.body)['machines']

      expect(machines.size).to eq(25)
    end
  end

  describe '#ic_toggle' do
    before(:each) do
      @lmx = FactoryBot.create(:location_machine_xref, id: 11, ic_enabled: nil, location: @location, machine: FactoryBot.create(:machine, id: 10, year: 2010, manufacturer: 'Williams', ic_eligible: true))
      @lmx2 = FactoryBot.create(:location_machine_xref, id: 12, ic_enabled: nil, location: @location, machine: FactoryBot.create(:machine, id: 22, year: 2012, manufacturer: 'Stern', ic_eligible: true))
      @lmx3 = FactoryBot.create(:location_machine_xref, id: 13, ic_enabled: nil, location: @location, machine: FactoryBot.create(:machine, id: 32, year: 2014, manufacturer: 'Stern', ic_eligible: false))
    end

    it 'toggles insider connected to be able to be toggled - authed' do
      put "/api/v1/location_machine_xrefs/#{@lmx.id}/ic_toggle.json", params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', HTTP_USER_AGENT: 'cleOS' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['location_machine']['ic_enabled']).to eq(true)

      get "/api/v1/location_machine_xrefs/#{@lmx.id}.json"
      expect(response).to be_successful

      lmx = JSON.parse(response.body)['location_machine']
      ic_enabled = lmx['ic_enabled']
      expect(ic_enabled).to be true

      put "/api/v1/location_machine_xrefs/#{@lmx.id}/ic_toggle.json", params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', HTTP_USER_AGENT: 'cleOS' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['location_machine']['ic_enabled']).to eq(false)

      get "/api/v1/location_machine_xrefs/#{@lmx.id}.json"
      expect(response).to be_successful

      lmx = JSON.parse(response.body)['location_machine']
      ic_enabled = lmx['ic_enabled']
      expect(ic_enabled).to be false
    end

    it 'does not allow non-eligible machines to be toggled - authed' do
      put "/api/v1/location_machine_xrefs/#{@lmx3.id}/ic_toggle.json", params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', HTTP_USER_AGENT: 'cleOS' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to match(/Could not update Insider Connected for this machine/)

      get "/api/v1/location_machine_xrefs/#{@lmx3.id}.json"
      expect(response).to be_successful

      lmx = JSON.parse(response.body)['location_machine']
      ic_enabled = lmx['ic_enabled']
      expect(ic_enabled).to be nil
    end

    it 'creates a user submission for the toggle - authed' do
      put "/api/v1/location_machine_xrefs/#{@lmx.id}/ic_toggle.json", params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', HTTP_USER_AGENT: 'cleOS' }
      expect(response).to be_successful

      get "/api/v1/user_submissions/location.json?id=#{@lmx.location.id};submission_type=ic_toggle"
      expect(response).to be_successful

      expect(JSON.parse(response.body)['user_submissions'][0]['submission_type']).to eq(UserSubmission::IC_TOGGLE_TYPE)
    end

    # check nil, toggle one machine, toggle both machines, toggle back one, toggle both off, toggle the final one to off.
    it 'toggles insider connected status on the Location correctly - authed' do
      # check nil
      get "/api/v1/locations/#{@lmx.location.id}.json"
      location = JSON.parse(response.body)
      expect(location['ic_active']).to be nil

      # toggle one on
      put "/api/v1/location_machine_xrefs/#{@lmx.id}/ic_toggle.json", params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', HTTP_USER_AGENT: 'cleOS' }
      get "/api/v1/locations/#{@lmx.location.id}.json"
      location = JSON.parse(response.body)
      expect(location['ic_active']).to be true

      # toggle both on
      put "/api/v1/location_machine_xrefs/#{@lmx2.id}/ic_toggle.json", params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', HTTP_USER_AGENT: 'cleOS' }
      get "/api/v1/locations/#{@lmx.location.id}.json"
      location = JSON.parse(response.body)
      expect(location['ic_active']).to be true

      # toggle one off
      put "/api/v1/location_machine_xrefs/#{@lmx.id}/ic_toggle.json", params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', HTTP_USER_AGENT: 'cleOS' }
      get "/api/v1/locations/#{@lmx.location.id}.json"
      location = JSON.parse(response.body)
      expect(location['ic_active']).to be true

      # toggle the other off
      put "/api/v1/location_machine_xrefs/#{@lmx2.id}/ic_toggle.json", params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', HTTP_USER_AGENT: 'cleOS' }
      get "/api/v1/locations/#{@lmx2.location.id}.json"
      location = JSON.parse(response.body)
      expect(location['ic_active']).to be false

      # toggle one back on
      put "/api/v1/location_machine_xrefs/#{@lmx2.id}/ic_toggle.json", params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', HTTP_USER_AGENT: 'cleOS' }
      get "/api/v1/locations/#{@lmx2.location.id}.json"
      location = JSON.parse(response.body)
      expect(location['ic_active']).to be true
    end

    it 'it should toggle via the ic_enabled param' do
      # don't toggle with nil
      put "/api/v1/location_machine_xrefs/#{@lmx.id}/ic_toggle.json", params: { ic_enabled: nil, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', HTTP_USER_AGENT: 'cleOS' }
      get "/api/v1/location_machine_xrefs/#{@lmx.id}.json", params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', HTTP_USER_AGENT: 'cleOS' }
      location = JSON.parse(response.body)
      expect(location['location_machine']['ic_enabled']).to be nil

      # set to false
      put "/api/v1/location_machine_xrefs/#{@lmx.id}/ic_toggle.json", params: { ic_enabled: 'false', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', HTTP_USER_AGENT: 'cleOS' }
      get "/api/v1/location_machine_xrefs/#{@lmx.id}.json", params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', HTTP_USER_AGENT: 'cleOS' }
      location = JSON.parse(response.body)
      expect(location['location_machine']['ic_enabled']).to be false

      # set to true
      put "/api/v1/location_machine_xrefs/#{@lmx.id}/ic_toggle.json", params: { ic_enabled: 'true', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', HTTP_USER_AGENT: 'cleOS' }
      get "/api/v1/location_machine_xrefs/#{@lmx.id}.json", params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', HTTP_USER_AGENT: 'cleOS' }
      location = JSON.parse(response.body)
      expect(location['location_machine']['ic_enabled']).to be true

      # set to false again
      put "/api/v1/location_machine_xrefs/#{@lmx.id}/ic_toggle.json", params: { ic_enabled: 'false', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', HTTP_USER_AGENT: 'cleOS' }
      get "/api/v1/location_machine_xrefs/#{@lmx.id}.json", params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', HTTP_USER_AGENT: 'cleOS' }
      location = JSON.parse(response.body)
      expect(location['location_machine']['ic_enabled']).to be false
    end

    it 'should not allow insider connect to be toggled when unauthed' do
      put "/api/v1/location_machine_xrefs/#{@lmx.id}/ic_toggle.json", params: { HTTP_USER_AGENT: 'cleOS' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to match(/Authentication is required/)
    end
  end
  describe '#most_recent_by_lat_lon' do
    it 'sends you the 5 most recent machines within N miles of your lat/lon' do
      get '/api/v1/location_machine_xrefs/most_recent_by_lat_lon.json', params: { lat: 45.49, lon: -122.63 }

      expect(JSON.parse(response.body)['errors']).to eq('No locations within 50 miles.')

      location = FactoryBot.create(:location, id: 10, region: @region, name: 'Location A', lat: 45.49, lon: -122.63)
      FactoryBot.create(:location_machine_xref, created_at: '2023-10-26T18:00:00', location: location, machine: FactoryBot.create(:machine, id: 200, name: 'Cleo'))
      FactoryBot.create(:location_machine_xref, created_at: '2023-10-26T18:01:00', location: location, machine: FactoryBot.create(:machine, id: 300, name: 'Steven'))

      another_location = FactoryBot.create(:location, id: 11, region: @region, name: 'Location B', lat: 45.49, lon: -122.63)
      FactoryBot.create(:location_machine_xref, created_at: '2023-10-26T18:02:00', location: another_location, machine: FactoryBot.create(:machine, id: 301, name: 'Garth'))
      FactoryBot.create(:location_machine_xref, created_at: '2023-10-26T18:03:00', location: another_location, machine: FactoryBot.create(:machine, id: 302, name: 'Zelda'))

      get '/api/v1/location_machine_xrefs/most_recent_by_lat_lon.json', params: { lat: location.lat, lon: location.lon }

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      most_recently_added_machines = parsed_body['most_recently_added_machines']
      expect(most_recently_added_machines.size).to eq(3)

      expect(most_recently_added_machines[0]).to eq('Steven @ Location A')
      expect(most_recently_added_machines[1]).to eq('Garth @ Location B')
      expect(most_recently_added_machines[2]).to eq('Zelda @ Location B')
    end
  end
end
