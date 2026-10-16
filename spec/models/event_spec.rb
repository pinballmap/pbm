require 'spec_helper'

describe Event do
  before(:each) do
  end

  describe 'coordinates' do
    let(:location) { FactoryBot.create(:location, lat: 45.524, lon: -122.676) }
    let(:address) { '303 Southeast 3rd Avenue, Portland, OR, 97214' } # stubbed in spec_helper

    around do |example|
      skip_geocode = ENV.delete('SKIP_GEOCODE')
      example.run
    ensure
      ENV['SKIP_GEOCODE'] = skip_geocode
    end

    it "uses the location's coordinates for a manual event" do
      e = FactoryBot.create(:event, location: location, address: address)
      expect([ e.latitude.to_f, e.longitude.to_f ]).to eq([ 45.524, -122.676 ])
    end

    it 'geocodes the address for a manual event without a location' do
      e = FactoryBot.create(:event, address: address)
      expect([ e.latitude.to_f.round(4), e.longitude.to_f.round(4) ]).to eq([ 45.5207, -122.6631 ])
    end

    it 'only geocodes again when the address changes' do
      e = FactoryBot.create(:event, address: address)
      expect(Geocoder).not_to receive(:search)
      e.update!(name: 'Renamed')
    end

    it 'clears coordinates when the address no longer geocodes or is removed' do
      e = FactoryBot.create(:event, address: address)
      e.update!(address: 'Nowhere at all')
      expect(e.latitude).to be_nil

      e = FactoryBot.create(:event, address: address)
      e.update!(address: '')
      expect(e.latitude).to be_nil
    end

    it 'switches to the location when one is added' do
      e = FactoryBot.create(:event, address: address)
      e.update!(location: location)
      expect(e.latitude.to_f).to eq(45.524)
    end

    it 'never changes coordinates on imported events' do
      expect(Geocoder).not_to receive(:search)
      e = FactoryBot.create(:event, ifpa_tournament_id: 1, address: address, location: location, latitude: 40.0, longitude: -80.0)
      expect([ e.latitude.to_f, e.longitude.to_f ]).to eq([ 40.0, -80.0 ])
    end
  end

  describe '#active?' do
    it 'should be active if there is no start or end date' do
      e = FactoryBot.create(:event, start_date: nil, end_date: nil)
      expect(e.active?).to be(1)
    end

    it 'handles start date with no end date' do
      e = FactoryBot.create(:event, start_date: Date.today, end_date: nil)
      expect(e.active?).to be(true)

      e = FactoryBot.create(:event, start_date: Date.today - 2.week, end_date: nil)
      expect(e.active?).to be(false)
    end

    it 'handles end date is present' do
      e = FactoryBot.create(:event, start_date: nil, end_date: Date.today)
      expect(e.active?).to be(true)

      e = FactoryBot.create(:event, start_date: nil, end_date: Date.today - 2.week)
      expect(e.active?).to be(false)
    end
  end
end
