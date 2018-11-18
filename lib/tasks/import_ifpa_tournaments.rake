desc 'Imports new IFPA tournaments into the pbm database'
task import_ifpa_tournaments: :environment do
  require 'net/http'
  require 'json'
  require 'openssl'

  # their ssl is broken, so we're using this for now
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

  IFPA_API_ROOT = 'https://api.ifpapinball.com/v1/'
  IFPA_API_KEY = ENV['IFPA_API_KEY']
  NUM_MILES_TO_SEARCH = 50

  Hash.new { |h, k| h[k] = [] }

  pbm_states = Location.all.pluck(:state).map(&:downcase!).uniq!

  JSON.parse(Net::HTTP.get(URI(IFPA_API_ROOT + '/calendar/active?api_key=' + IFPA_API_KEY.to_s)))['calendar'].each do |c|
    state = c['state'].downcase

    next unless pbm_states.include?(state) && !Event.exists?(ifpa_tournament_id: c['tournament_id'], ifpa_calendar_id: c['calendar_id'])

    p 'Adding: ' + c['tournament_name']

    cd = nil
    begin
      cd = JSON.parse(Net::HTTP.get(URI(IFPA_API_ROOT + '/calendar/' + c['calendar_id'] + '?api_key=' + IFPA_API_KEY.to_s)))['calendar'].first
    rescue JSON::ParserError
      p 'SKIPPING'
      next
    end

    associated_location = nil
    if cd['latitude'] && cd['longitude'] && cd['zipcode']
      associated_location = Location.where('zip = ?', cd['zipcode'].to_s).select { |l| l.lat.to_f.round(4).to_s == cd['latitude'] && l.lon.to_f.round(4).to_s == cd['longitude'] }.first
    end

    location_id = nil
    long_desc = Sanitize.clean(cd['details']).truncate(300)

    if associated_location
      location_id = associated_location.id
    else
      long_desc << "\n#{cd['address1']}, #{cd['city']}, #{cd['state']}, #{cd['zipcode']}"
    end

    region_ids_to_add_event_to = []
    Location.near([cd['latitude'].to_f, cd['longitude'].to_f], NUM_MILES_TO_SEARCH).each do |l|
      region_ids_to_add_event_to.push(l.region_id)
    end

    end_date = c['start_date'] != c['end_date'] ? c['end_date'] : nil

    region_ids_to_add_event_to.uniq.each do |region_id|
      Event.create(
        ifpa_tournament_id: c['tournament_id'].to_i,
        ifpa_calendar_id: c['calendar_id'].to_i,
        name: c['tournament_name'],
        external_link: cd['website'],
        long_desc: long_desc,
        start_date: c['start_date'],
        end_date: end_date,
        location_id: location_id,
        region_id: region_id,
        category: 'IFPA Sanctioned Events'
      )
    end
  end
end
