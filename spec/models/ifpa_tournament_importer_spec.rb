require 'spec_helper'

describe IfpaTournamentImporter do
  let(:today) { Date.new(2026, 10, 15) }
  let(:region) { FactoryBot.create(:region, name: 'portland', lat: 45.52, lon: -122.68) }
  let(:location) { FactoryBot.create(:location, region: region, name: 'Ground Kontrol', street: '115 NW 5th Ave', city: 'Portland', state: 'OR', zip: '97209', lat: 45.524, lon: -122.676) }

  def tournament(attrs = {})
    {
      'tournament_id' => '1001',
      'tournament_name' => 'Monday Night Strikes ',
      'event_type' => 'Tournament',
      'location_name' => 'Ground Kontrol',
      'address1' => '115 NW 5th Ave',
      'city' => 'Portland',
      'stateprov' => 'OR',
      'postal_code' => '97209',
      'country_code' => 'US',
      'event_start_date' => '2026-10-20',
      'event_end_date' => '2026-10-20',
      'latitude' => '45.524',
      'longitude' => '-122.676',
      'raw_address' => '115 NW 5th Ave  Portland, OR 97209',
      'private_flag' => 'false',
      'ranking_system' => 'MAIN',
      'website' => 'https://example.com',
      'details' => "Strikes!\r\n"
    }.merge(attrs)
  end

  # responses: one entry per request, either an array of tournaments or a full response hash
  def stub_ifpa(*responses)
    @requested_uris = []
    http = instance_double(Net::HTTP)
    allow(http).to receive(:get) do |path|
      @requested_uris << path
      body = responses[@requested_uris.size - 1] || []
      body = { 'total_results' => body.size.to_s, 'tournaments' => body } if body.is_a?(Array)
      instance_double(Net::HTTPOK, code: '200', body: body.to_json)
    end
    allow(Net::HTTP).to receive(:start).and_yield(http)
  end

  def run(months: 2, page_size: IfpaTournamentImporter::PAGE_SIZE)
    IfpaTournamentImporter.run(start_date: today, months: months, page_size: page_size, pause_seconds: 0, logger: nil)
  end

  def requested_queries
    @requested_uris.map { |uri| Rack::Utils.parse_query(URI(uri).query) }
  end

  it 'requests the whole range at once with the page size' do
    stub_ifpa
    run(months: 3)

    expect(requested_queries.map { |q| q.slice('start_date', 'end_date', 'total', 'start_pos') }).to eq([
      { 'start_date' => '2026-10-15', 'end_date' => '2027-01-14', 'total' => '250', 'start_pos' => '1' }
    ])
  end

  describe 'paging' do
    def page(ids, total)
      { 'total_results' => total.to_s, 'tournaments' => ids.map { |id| tournament('tournament_id' => id.to_s, 'location_name' => nil) } }
    end

    it 'requests pages until it has every tournament in the range' do
      stub_ifpa(page([ 1, 2 ], 5), page([ 3, 4 ], 5), page([ 5 ], 5))
      importer = run(page_size: 2)

      expect(requested_queries.map { |q| q['start_pos'] }).to eq(%w[1 3 5])
      expect(Event.pluck(:ifpa_tournament_id)).to match_array([ 1, 2, 3, 4, 5 ])
      expect(importer.errors).to be_empty
    end

    it 'stops at the last full page when it lines up with total_results' do
      stub_ifpa(page([ 1, 2 ], 4), page([ 3, 4 ], 4))
      run(page_size: 2)

      expect(requested_queries.map { |q| q['start_pos'] }).to eq(%w[1 3])
    end

    it 'deletes canceled events once every page is fetched' do
      canceled = FactoryBot.create(:event, ifpa_tournament_id: 99, start_date: '2026-10-20', end_date: '2026-10-20')
      stub_ifpa(page([ 1, 2 ], 3), page([ 3 ], 3))
      run(page_size: 2)

      expect(Event.exists?(canceled.id)).to be false
    end

    it 'counts a tournament listed once per director as fully fetched' do
      canceled = FactoryBot.create(:event, ifpa_tournament_id: 99, start_date: '2026-10-20', end_date: '2026-10-20')
      stub_ifpa({ 'total_results' => '2', 'tournaments' => [ tournament('director_id' => '1'), tournament('director_id' => '2') ] })
      importer = run

      expect(Event.pluck(:ifpa_tournament_id)).to eq([ 1001 ])
      expect(Event.exists?(canceled.id)).to be false
      expect(importer.errors).to be_empty
    end

    it 'does not delete when a later page failed' do
      kept = FactoryBot.create(:event, ifpa_tournament_id: 99, start_date: '2026-10-20', end_date: '2026-10-20')
      http = instance_double(Net::HTTP)
      responses = [
        instance_double(Net::HTTPOK, code: '200', body: page([ 1, 2 ], 3).to_json),
        instance_double(Net::HTTPOK, code: '500', body: 'oops')
      ]
      allow(http).to receive(:get) { responses.shift }
      allow(Net::HTTP).to receive(:start).and_yield(http)
      importer = run(page_size: 2)

      expect(Event.exists?(kept.id)).to be true
      expect(Event.where(ifpa_tournament_id: [ 1, 2 ]).count).to eq(2)
      expect(importer.errors).to include(a_string_including('from 3 request failed: 500'), a_string_including('fetched 2 of 3'))
    end

    it 'does not delete when results shifted between pages and a tournament came back twice' do
      kept = FactoryBot.create(:event, ifpa_tournament_id: 99, start_date: '2026-10-20', end_date: '2026-10-20')
      stub_ifpa(page([ 1, 2 ], 3), page([ 2 ], 3))
      importer = run(page_size: 2)

      expect(Event.exists?(kept.id)).to be true
      expect(importer.errors.first).to include('fetched 2 of 3')
    end
  end

  it 'creates one event per tournament with the matched location, its region, address and coordinates' do
    location
    stub_ifpa([ tournament('raw_address' => '115 NW Fifth Avenue Portland Oregon', 'latitude' => '45.5245', 'longitude' => '-122.6765') ])
    run

    event = Event.sole
    expect(event).to have_attributes(
      ifpa_tournament_id: 1001, name: 'Monday Night Strikes', start_date: Date.new(2026, 10, 20), end_date: Date.new(2026, 10, 20),
      external_link: 'https://example.com', long_desc: 'Strikes!', address: '115 NW 5th Ave, Portland, OR, 97209',
      external_location_name: 'Ground Kontrol', event_type: 'Tournament', ranking: 'Open', location_id: location.id, region_id: region.id,
      category: 'IFPA Sanctioned Events'
    )
    expect([ event.latitude.to_f, event.longitude.to_f ]).to eq([ 45.524, -122.676 ])
  end

  it "keeps IFPA's address and coordinates and uses the region of the nearest location within 100 miles when unmatched" do
    location
    stub_ifpa([ tournament('address1' => '1 Other St', 'location_name' => nil, 'raw_address' => '1 Other St  Portland, OR', 'latitude' => '45.0', 'longitude' => '-122.5') ])
    run

    event = Event.sole
    expect(event).to have_attributes(location_id: nil, region_id: region.id, address: '1 Other St Portland, OR')
    expect([ event.latitude.to_f, event.longitude.to_f ]).to eq([ 45.0, -122.5 ])
  end

  it 'leaves region empty when nothing is within 100 miles' do
    location
    stub_ifpa([ tournament('latitude' => '40.0', 'longitude' => '-100.0') ])
    run

    expect(Event.sole).to have_attributes(location_id: nil, region_id: nil)
  end

  it 'updates existing events with changed fields' do
    stub_ifpa([ tournament ])
    run
    stub_ifpa([ tournament('tournament_name' => 'Renamed', 'event_start_date' => '2026-10-21', 'event_end_date' => '2026-10-22') ])
    importer = run

    expect(Event.sole).to have_attributes(name: 'Renamed', start_date: Date.new(2026, 10, 21), end_date: Date.new(2026, 10, 22))
    expect(importer.stats[:updated]).to eq(1)
  end

  it 'collapses duplicate rows from the old per-region import' do
    3.times { FactoryBot.create(:event, ifpa_tournament_id: 1001, start_date: '2026-10-20') }
    stub_ifpa([ tournament ])
    run

    expect(Event.where(ifpa_tournament_id: 1001).count).to eq(1)
  end

  it 'skips private tournaments and removes ones that became private' do
    FactoryBot.create(:event, ifpa_tournament_id: 1002, start_date: '2026-10-20')
    stub_ifpa([ tournament('private_flag' => 'true'), tournament('tournament_id' => '1002', 'private_flag' => 'true') ])
    run

    expect(Event.count).to eq(0)
  end

  it 'skips virtual tournaments and removes ones that became virtual, but keeps women and main ones' do
    FactoryBot.create(:event, ifpa_tournament_id: 1002, start_date: '2026-10-20')
    stub_ifpa([
      tournament('ranking_system' => 'VIRTUAL'),
      tournament('tournament_id' => '1002', 'ranking_system' => 'VIRTUAL'),
      tournament('tournament_id' => '1003', 'ranking_system' => 'WOMEN'),
      tournament('tournament_id' => '1004', 'ranking_system' => 'MAIN')
    ])
    run

    expect(Event.pluck(:ifpa_tournament_id, :ranking)).to contain_exactly([ 1003, 'Women' ], [ 1004, 'Open' ])
  end

  it 'stores rankings IFPA adds later in title case, and none when IFPA sends none' do
    stub_ifpa([ tournament('ranking_system' => 'SENIOR'), tournament('tournament_id' => '1002', 'ranking_system' => '') ])
    run

    expect(Event.pluck(:ifpa_tournament_id, :ranking)).to contain_exactly([ 1001, 'Senior' ], [ 1002, nil ])
  end

  it 'deletes IFPA events in the fetched range that IFPA no longer returns' do
    canceled = FactoryBot.create(:event, ifpa_tournament_id: 2001, start_date: '2026-11-20', end_date: '2026-11-22')
    stub_ifpa([ tournament ])
    run

    expect(Event.exists?(canceled.id)).to be false
    expect(Event.pluck(:ifpa_tournament_id)).to eq([ 1001 ])
  end

  it 'keeps a tournament moved to a later month' do
    stub_ifpa([ tournament ])
    run
    stub_ifpa([ tournament('event_start_date' => '2026-11-20', 'event_end_date' => '2026-11-20') ])
    run

    expect(Event.sole.start_date).to eq(Date.new(2026, 11, 20))
  end

  it 'does not delete events that started before today, non-IFPA events, or events ending past the fetched range' do
    past = FactoryBot.create(:event, ifpa_tournament_id: 2001, start_date: '2026-10-14', end_date: '2026-10-14')
    manual = FactoryBot.create(:event, start_date: '2026-10-20', end_date: '2026-10-20')
    manual_later = FactoryBot.create(:event, start_date: '2027-01-20', end_date: '2027-01-20')
    extended = FactoryBot.create(:event, ifpa_tournament_id: 2003, start_date: '2026-11-20', end_date: '2027-01-20')
    stub_ifpa([])
    run

    expect(Event.where(id: [ past.id, manual.id, manual_later.id, extended.id ]).count).to eq(4)
  end

  it 'deletes IFPA events starting past the fetched range' do
    later = FactoryBot.create(:event, ifpa_tournament_id: 2002, start_date: '2026-12-15', end_date: '2026-12-15')
    typo = FactoryBot.create(:event, ifpa_tournament_id: 2004, start_date: '2109-11-15', end_date: nil)
    last_day = FactoryBot.create(:event, ifpa_tournament_id: 1001, start_date: '2026-12-14', end_date: '2026-12-14')
    stub_ifpa([ tournament('event_start_date' => '2026-12-14', 'event_end_date' => '2026-12-14') ])
    run

    expect(Event.exists?(later.id)).to be false
    expect(Event.exists?(typo.id)).to be false
    expect(Event.exists?(last_day.id)).to be true
  end

  it 'does not delete events past the fetched range when the results were truncated' do
    kept = FactoryBot.create(:event, ifpa_tournament_id: 2002, start_date: '2027-01-20', end_date: '2027-01-20')
    stub_ifpa({ 'total_results' => '2500', 'tournaments' => [ tournament ] })
    run

    expect(Event.exists?(kept.id)).to be true
  end

  it 'does not delete when the results were truncated' do
    kept = FactoryBot.create(:event, ifpa_tournament_id: 2001, start_date: '2026-10-20', end_date: '2026-10-20')
    stub_ifpa({ 'total_results' => '2500', 'tournaments' => [ tournament ] })
    importer = run

    expect(Event.exists?(kept.id)).to be true
    expect(importer.errors.first).to include('fetched 1 of 2500')
  end

  it 'does not delete when the request failed' do
    kept = FactoryBot.create(:event, ifpa_tournament_id: 2001, start_date: '2026-10-20', end_date: '2026-10-20')
    http = instance_double(Net::HTTP)
    allow(http).to receive(:get).and_return(instance_double(Net::HTTPOK, code: '500', body: 'oops'))
    allow(Net::HTTP).to receive(:start).and_yield(http)
    importer = run

    expect(Event.exists?(kept.id)).to be true
    expect(importer.errors).to eq([ '2026-10-15..2026-12-14 from 1 request failed: 500 oops' ])
  end
end
