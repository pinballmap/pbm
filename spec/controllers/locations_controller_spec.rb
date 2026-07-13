require 'spec_helper'

describe LocationsController, type: :controller do
  before(:each) do
    @user = FactoryBot.create(:user, username: 'ssw', email: 'ssw@yeah.com', id: 1111)
    login(@user)

    region = FactoryBot.create(:region, name: 'portland')
    @location = FactoryBot.create(:location, id: 777, region: region)
    @machine = FactoryBot.create(:machine)
    FactoryBot.create(:user, email: 'foo@bar.com', region: region)
  end

  describe '#update_metadata' do
    it 'should return error json when phone number is in an invalid format' do
      get 'update_metadata', params: { region: 'portland', id: @location.id, new_phone_777: 'invalid' }

      expect(response.body).to eq('{"error":"Invalid phone format."}')
    end

    it 'should return error json when website is in an invalid format' do
      get 'update_metadata', params: { region: 'portland', id: @location.id, new_website_777: 'invalid' }

      expect(response.body).to eq('{"error":"Website must begin with http:// or https://"}')
    end
  end

  describe '#render_recent_activity' do
    before(:each) do
      @lmx_submission = FactoryBot.create(:user_submission, location: @location, submission_type: 'new_lmx', submission: 'Machine added at location', location_name: @location.name)
      @remove_submission = FactoryBot.create(:user_submission, location: @location, submission_type: 'remove_machine', submission: 'Machine removed from location', location_name: @location.name)
      @score_submission = FactoryBot.create(:user_submission, location: @location, submission_type: 'new_msx', user: @user, submission: 'Score added at location', location_name: @location.name)
    end

    it 'returns all activity types when no filter is specified' do
      get 'render_recent_activity', params: { id: @location.id }

      expect(response).to be_successful
      submissions = assigns(:recent_activity)
      expect(submissions).to include(@lmx_submission)
      expect(submissions).to include(@remove_submission)
      expect(submissions).to include(@score_submission)
    end

    it 'filters to a single specified submission type' do
      get 'render_recent_activity', params: { id: @location.id, submission_type: [ 'new_lmx' ] }

      expect(response).to be_successful
      submissions = assigns(:recent_activity)
      expect(submissions).to include(@lmx_submission)
      expect(submissions).to_not include(@remove_submission)
      expect(submissions).to_not include(@score_submission)
    end

    it 'filters to multiple specified submission types' do
      get 'render_recent_activity', params: { id: @location.id, submission_type: [ 'new_lmx', 'remove_machine' ] }

      expect(response).to be_successful
      submissions = assigns(:recent_activity)
      expect(submissions).to include(@lmx_submission)
      expect(submissions).to include(@remove_submission)
      expect(submissions).to_not include(@score_submission)
    end

    it 'returns only the current user\'s scores when new_msx is the only filter' do
      other_user = FactoryBot.create(:user, username: 'other', email: 'other@example.com')
      other_score = FactoryBot.create(:user_submission, location: @location, submission_type: 'new_msx', user: other_user, submission: 'Other user score', location_name: @location.name)

      get 'render_recent_activity', params: { id: @location.id, submission_type: [ 'new_msx' ] }

      expect(response).to be_successful
      submissions = assigns(:recent_activity)
      expect(submissions).to include(@score_submission)
      expect(submissions).to_not include(other_score)
    end

    it 'does not return new_msx submissions when logged out and new_msx is the only filter' do
      login(nil)

      get 'render_recent_activity', params: { id: @location.id, submission_type: [ 'new_msx' ] }

      expect(response).to be_successful
      expect(assigns(:recent_activity)).to be_empty
    end

    it 'does not return new_msx submissions when logged out and no filter is specified' do
      login(nil)

      get 'render_recent_activity', params: { id: @location.id }

      expect(response).to be_successful
      submissions = assigns(:recent_activity)
      expect(submissions).to include(@lmx_submission)
      expect(submissions).to_not include(@score_submission)
    end

    it 'returns all activity types when an empty filter array is given' do
      get 'render_recent_activity', params: { id: @location.id, submission_type: [] }

      expect(response).to be_successful
      submissions = assigns(:recent_activity)
      expect(submissions).to include(@lmx_submission)
      expect(submissions).to include(@remove_submission)
      expect(submissions).to include(@score_submission)
    end

    it 'returns 404 for an unknown location' do
      get 'render_recent_activity', params: { id: 99999 }

      expect(response.status).to eq(404)
    end
  end

  describe '#random_machine' do
    it 'is accessible when logged out' do
      login(nil)
      FactoryBot.create(:location_machine_xref, location: @location, machine: @machine)

      get 'random_machine', params: { id: @location.id }

      expect(response).to be_successful
    end
  end

  describe '#render_location_detail' do
    render_views

    it 'does not show the random machine icon when the location has no machines' do
      get 'render_location_detail', params: { id: @location.id }

      expect(response).to be_successful
      expect(response.body).to_not include('class="random_machine_icon"')
    end

    it 'does not show the random machine icon when the location has only one machine' do
      FactoryBot.create(:location_machine_xref, location: @location, machine: @machine)

      get 'render_location_detail', params: { id: @location.id }

      expect(response).to be_successful
      expect(response.body).to_not include('class="random_machine_icon"')
    end

    it 'shows the random machine icon when the location has more than one machine' do
      FactoryBot.create(:location_machine_xref, location: @location, machine: @machine)
      FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine))

      get 'render_location_detail', params: { id: @location.id }

      expect(response).to be_successful
      expect(response.body).to include('class="random_machine_icon"')
    end

    it 'shows the random machine icon after a second machine is added to a location that had one' do
      FactoryBot.create(:location_machine_xref, location: @location, machine: @machine)

      get 'render_location_detail', params: { id: @location.id }
      expect(response.body).to_not include('class="random_machine_icon"')

      FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine))

      get 'render_location_detail', params: { id: @location.id }
      expect(response.body).to include('class="random_machine_icon"')
    end

    it 'does not show the machine sort icon when the location has one or fewer machines' do
      FactoryBot.create(:location_machine_xref, location: @location, machine: @machine)

      get 'render_location_detail', params: { id: @location.id }

      expect(response).to be_successful
      expect(response.body).to_not include('class="machine_sort_icon"')
    end

    it 'shows the machine sort icon when the location has more than one machine' do
      FactoryBot.create(:location_machine_xref, location: @location, machine: @machine)
      FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine))

      get 'render_location_detail', params: { id: @location.id }

      expect(response).to be_successful
      expect(response.body).to include('class="machine_sort_icon"')
    end
  end

  describe '#render_machines' do
    render_views

    let(:zaphod) { FactoryBot.create(:machine, name: 'Zaphod', year: 1990, manufacturer: 'Zeta Corp', lmx_count: 5) }
    let(:apple) { FactoryBot.create(:machine, name: 'Apple Delight', year: 2010, manufacturer: 'Acme', lmx_count: 50) }
    let(:the_beast) { FactoryBot.create(:machine, name: 'The Beast', year: 2000, manufacturer: 'Midway', lmx_count: 20) }

    before(:each) do
      FactoryBot.create(:location_machine_xref, location: @location, machine: zaphod)
      FactoryBot.create(:location_machine_xref, location: @location, machine: apple)
      FactoryBot.create(:location_machine_xref, location: @location, machine: the_beast)
    end

    def machine_order_from_response
      response.body.scan(/machine_name">\s*(.*?)\s*</).flatten
    end

    it 'defaults to alphabetical order (ignoring a leading "The") for an unrecognized sort param' do
      get 'render_machines', params: { id: @location.id, sort: 'bogus' }

      expect(machine_order_from_response).to eq([ 'Apple Delight', 'The Beast', 'Zaphod' ])
    end

    it 'sorts by year, newest first' do
      get 'render_machines', params: { id: @location.id, sort: 'year_newest' }

      expect(machine_order_from_response).to eq([ 'Apple Delight', 'The Beast', 'Zaphod' ])
    end

    it 'sorts by year, oldest first' do
      get 'render_machines', params: { id: @location.id, sort: 'year_oldest' }

      expect(machine_order_from_response).to eq([ 'Zaphod', 'The Beast', 'Apple Delight' ])
    end

    it 'sorts rarest first by lmx_count ascending' do
      get 'render_machines', params: { id: @location.id, sort: 'rarest' }

      expect(machine_order_from_response).to eq([ 'Zaphod', 'The Beast', 'Apple Delight' ])
    end

    it 'sorts most common first by lmx_count descending' do
      get 'render_machines', params: { id: @location.id, sort: 'most_common' }

      expect(machine_order_from_response).to eq([ 'Apple Delight', 'The Beast', 'Zaphod' ])
    end

    it 'sorts alphabetically by manufacturer' do
      get 'render_machines', params: { id: @location.id, sort: 'manufacturer' }

      expect(machine_order_from_response).to eq([ 'Apple Delight', 'The Beast', 'Zaphod' ])
    end

    it 'sorts machines not in the life list first, then alphabetically, when logged in' do
      FactoryBot.create(:user_machine_xref, user: @user, machine: apple)

      get 'render_machines', params: { id: @location.id, sort: 'not_in_life_list' }

      expect(machine_order_from_response).to eq([ 'The Beast', 'Zaphod', 'Apple Delight' ])
    end
  end
end
