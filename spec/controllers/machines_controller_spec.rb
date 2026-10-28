require 'spec_helper'

describe MachinesController, type: :controller do
  describe '#autocomplete' do
    let(:zaphod) { FactoryBot.create(:machine, name: 'Zaphod', year: 1990, manufacturer: 'Zeta Corp', lmx_count: 5) }
    let(:apple) { FactoryBot.create(:machine, name: 'Apple Delight', year: 2010, manufacturer: 'Acme', lmx_count: 50) }
    let(:the_beast) { FactoryBot.create(:machine, name: 'The Beast', year: 2000, manufacturer: 'Midway', lmx_count: 20) }

    before(:each) do
      zaphod
      apple
      the_beast
    end

    def machine_names_from_response
      JSON.parse(response.body).map { |m| m['label'] }
    end

    it 'defaults to alphabetical order (ignoring a leading "The") when no sort param is given' do
      get 'autocomplete', params: { term: '' }

      expect(machine_names_from_response).to eq([ 'Apple Delight (Acme, 2010)', 'The Beast (Midway, 2000)', 'Zaphod (Zeta Corp, 1990)' ])
    end

    it 'falls back to alphabetical for an unrecognized sort param' do
      get 'autocomplete', params: { term: '', sort: 'bogus' }

      expect(machine_names_from_response).to eq([ 'Apple Delight (Acme, 2010)', 'The Beast (Midway, 2000)', 'Zaphod (Zeta Corp, 1990)' ])
    end

    it 'sorts by year, newest first' do
      get 'autocomplete', params: { term: '', sort: 'year_newest' }

      expect(machine_names_from_response).to eq([ 'Apple Delight (Acme, 2010)', 'The Beast (Midway, 2000)', 'Zaphod (Zeta Corp, 1990)' ])
    end

    it 'sorts by year, oldest first' do
      get 'autocomplete', params: { term: '', sort: 'year_oldest' }

      expect(machine_names_from_response).to eq([ 'Zaphod (Zeta Corp, 1990)', 'The Beast (Midway, 2000)', 'Apple Delight (Acme, 2010)' ])
    end

    it 'sorts rarest first by lmx_count ascending' do
      get 'autocomplete', params: { term: '', sort: 'rarest' }

      expect(machine_names_from_response).to eq([ 'Zaphod (Zeta Corp, 1990)', 'The Beast (Midway, 2000)', 'Apple Delight (Acme, 2010)' ])
    end

    it 'sorts most common first by lmx_count descending' do
      get 'autocomplete', params: { term: '', sort: 'most_common' }

      expect(machine_names_from_response).to eq([ 'Apple Delight (Acme, 2010)', 'The Beast (Midway, 2000)', 'Zaphod (Zeta Corp, 1990)' ])
    end

    it 'sorts alphabetically by manufacturer' do
      get 'autocomplete', params: { term: '', sort: 'manufacturer' }

      expect(machine_names_from_response).to eq([ 'Apple Delight (Acme, 2010)', 'The Beast (Midway, 2000)', 'Zaphod (Zeta Corp, 1990)' ])
    end

    it 'sorts machines not in the current user\'s life list first, then alphabetically, when logged in' do
      user = FactoryBot.create(:user, email: 'ssw@yeah.test')
      login(user)
      FactoryBot.create(:user_machine_xref, user: user, machine: apple)

      get 'autocomplete', params: { term: '', sort: 'not_in_life_list' }

      expect(machine_names_from_response).to eq([ 'The Beast (Midway, 2000)', 'Zaphod (Zeta Corp, 1990)', 'Apple Delight (Acme, 2010)' ])
    end

    it 'does not error when sorting by life list while logged out' do
      get 'autocomplete', params: { term: '', sort: 'not_in_life_list' }

      expect(response).to be_successful
      expect(machine_names_from_response).to eq([ 'Apple Delight (Acme, 2010)', 'The Beast (Midway, 2000)', 'Zaphod (Zeta Corp, 1990)' ])
    end

    it 'only returns machines at locations in the requested region for a region level search' do
      portland = FactoryBot.create(:region, name: 'portland')
      atlanta = FactoryBot.create(:region, name: 'atlanta')
      FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, region: portland), machine: zaphod)
      FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, region: atlanta), machine: apple)

      get 'autocomplete', params: { term: '', region_level_search: '1', region: 'atlanta' }

      expect(machine_names_from_response).to eq([ 'Apple Delight (Acme, 2010)' ])
    end

    it 'falls back to searching all machines for a region level search with an unknown region' do
      get 'autocomplete', params: { term: '', region_level_search: '1', region: 'nowhere' }

      expect(machine_names_from_response).to eq([ 'Apple Delight (Acme, 2010)', 'The Beast (Midway, 2000)', 'Zaphod (Zeta Corp, 1990)' ])
    end
  end

  describe '#opdb_img' do
    it 'returns the opdb_img and ic_eligible for a machine' do
      machine = FactoryBot.create(:machine, opdb_img: '/public/favicon.ico', ic_eligible: true)

      get 'opdb_img', params: { id: machine.id }

      expect(JSON.parse(response.body)).to eq('opdb_img' => '/public/favicon.ico', 'ic_eligible' => true)
    end

    it 'returns nil opdb_img and false ic_eligible when the machine has neither' do
      machine = FactoryBot.create(:machine, opdb_img: nil, ic_eligible: false)

      get 'opdb_img', params: { id: machine.id }

      expect(JSON.parse(response.body)).to eq('opdb_img' => nil, 'ic_eligible' => false)
    end

    it 'returns whether the machine is already at the location when a location_id is passed' do
      machine = FactoryBot.create(:machine)
      location = FactoryBot.create(:location)
      other_location = FactoryBot.create(:location)
      FactoryBot.create(:location_machine_xref, location: location, machine: machine)

      get 'opdb_img', params: { id: machine.id, location_id: location.id }
      expect(JSON.parse(response.body)['already_at_location']).to eq(true)

      get 'opdb_img', params: { id: machine.id, location_id: other_location.id }
      expect(JSON.parse(response.body)['already_at_location']).to eq(false)
    end
  end
end
