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
      user = FactoryBot.create(:user, email: 'ssw@yeah.com')
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
  end
end
