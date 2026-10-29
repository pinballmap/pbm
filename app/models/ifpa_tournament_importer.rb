require "net/http"
require "json"

# Syncs upcoming IFPA tournaments into Events, one row per tournament.
#
# The next MONTHS of tournaments are fetched as one date range, in pages of PAGE_SIZE (IFPA's maximum), pausing between
# requests to go easy on IFPA's server. IFPA only returns tournaments that start and end within the range, so it isn't
# split into smaller ranges: a multi-day tournament crossing a split would be in neither. Each page is saved before the
# next is requested. Every run overwrites the fields we use, so edits on IFPA's side come through.
#
# Once every page is fetched, IFPA events within the range that IFPA no longer returned are deleted as canceled. The
# range counts as fully fetched only when we got as many distinct tournament and director rows as IFPA's
# total_results, so a failed page, or results shifting between pages, never causes deletions. IFPA events starting
# after the range are deleted too.
#
# Events starting before today are never deleted, so timezone differences can't remove an event before it happens.
class IfpaTournamentImporter
  IFPA_SEARCH_URL = "https://api.ifpapinball.com/tournament/search".freeze
  CATEGORY = "IFPA Sanctioned Events".freeze
  MONTHS = 6
  PAGE_SIZE = 250
  # A safety stop, well above the ~3000 tournaments we see over six months
  MAX_PAGES = 60
  REGION_SEARCH_MILES = 100
  PAUSE_SECONDS = 8

  attr_reader :errors, :stats

  def self.run(...)
    new(...).run
  end

  def initialize(start_date: Date.current, months: MONTHS, page_size: PAGE_SIZE, pause_seconds: PAUSE_SECONDS, logger: Rails.logger)
    @start_date = start_date
    @end_date = start_date.next_month(months) - 1
    @page_size = page_size
    @pause_seconds = pause_seconds
    @logger = logger
    @errors = []
    @stats = Hash.new(0)
  end

  def run
    seen_ids = Set.new
    # IFPA returns a tournament once per director, so rows are counted by tournament and director
    seen_rows = Set.new
    total_results = nil
    start_pos = 1

    MAX_PAGES.times do |i|
      sleep(@pause_seconds) if i.positive?

      response = fetch(start_pos)
      break unless response

      tournaments = Array(response["tournaments"])
      total_results = response["total_results"].to_i
      tournaments.each do |t|
        seen_ids << t["tournament_id"].to_i
        seen_rows << [ t["tournament_id"].to_i, t["director_id"].to_i ]
        import(t)
      end

      start_pos += @page_size
      break if tournaments.size < @page_size || start_pos > total_results
    end

    # A failed first request has already been reported
    if total_results && seen_rows.size < total_results
      add_error("#{@start_date}..#{@end_date} fetched #{seen_rows.size} of #{total_results} tournaments; skipping deletions")
    elsif total_results
      delete_canceled(seen_ids)
    end

    log("IFPA import: #{@stats.sort.map { |k, v| "#{k}=#{v}" }.join(' ')}")
    self
  end

  private

  # start_pos counts from 1
  def fetch(start_pos)
    uri = URI(IFPA_SEARCH_URL)
    uri.query = URI.encode_www_form(
      api_key: ENV.fetch("IFPA_API_KEY", ""),
      total: @page_size,
      start_pos: start_pos,
      start_date: @start_date.iso8601,
      end_date: @end_date.iso8601
    )
    request = "#{@start_date}..#{@end_date} from #{start_pos}"

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 60) do |http|
      http.get(uri.request_uri)
    end
    unless response.code == "200"
      add_error("#{request} request failed: #{response.code} #{response.body.to_s.truncate(200)}")
      return
    end

    JSON.parse(response.body)
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError, OpenSSL::SSL::SSLError, JSON::ParserError => e
    add_error("#{request} request failed: #{e.class}: #{e.message}")
    nil
  end

  def import(t)
    tournament_id = t["tournament_id"].to_i
    return if tournament_id.zero?

    # Older imports made one row per nearby region; collapse those into one
    rows = Event.where(ifpa_tournament_id: tournament_id).order(:id).to_a
    event = rows.shift || Event.new(ifpa_tournament_id: tournament_id, category: CATEGORY)
    Event.where(id: rows.map(&:id)).delete_all if rows.any?

    skip_reason = if t["private_flag"].to_s == "true"
      :private
    elsif t["ranking_system"].to_s.casecmp?("VIRTUAL")
      # Online tournaments have no venue to show
      :virtual
    end
    if skip_reason
      if event.persisted?
        event.destroy
        @stats[:"deleted_#{skip_reason}"] += 1
      end
      return
    end

    # A matched event takes our location's address and coordinates, which are usually better than IFPA's
    location = IfpaLocationMatcher.match(t).location
    if location
      address = location.full_street_address
      lat, lon = location.lat, location.lon
    else
      address = t["raw_address"].to_s.squish.presence
      lat = Float(t["latitude"], exception: false)
      lon = Float(t["longitude"], exception: false)
    end

    event.assign_attributes(
      name: t["tournament_name"].to_s.strip,
      start_date: t["event_start_date"],
      end_date: t["event_end_date"].presence || t["event_start_date"],
      external_link: t["website"].presence,
      long_desc: t["details"].to_s.strip.presence,
      address: address,
      external_location_name: t["location_name"].to_s.strip.presence,
      event_type: t["event_type"].presence,
      ranking: ranking_label(t["ranking_system"]),
      latitude: lat,
      longitude: lon,
      location_id: location&.id,
      region_id: location ? location.region_id : nearest_region_id(lat, lon)
    )

    if event.new_record?
      event.save!
      @stats[:created] += 1
    elsif event.changed?
      event.save!
      @stats[:updated] += 1
    else
      @stats[:unchanged] += 1
    end
  rescue ActiveRecord::ActiveRecordError, ArgumentError => e
    add_error("Tournament #{t['tournament_id']} failed: #{e.class}: #{e.message}")
  end

  # IFPA sends e.g. MAIN, WOMEN, YOUTH, and shows MAIN as Open on its calendar
  def ranking_label(ranking_system)
    ranking_system = ranking_system.to_s.strip
    return if ranking_system.empty?

    ranking_system.casecmp?("MAIN") ? "Open" : ranking_system.capitalize
  end

  def nearest_region_id(lat, lon)
    return unless lat && lon && !(lat.zero? && lon.zero?)

    Location.where.not(region_id: nil).near([ lat, lon ], REGION_SEARCH_MILES).first&.region_id
  end

  # An event extended past the range is no longer returned, so only events ending within it are checked
  def delete_canceled(seen_ids)
    ifpa_events = Event.where.not(ifpa_tournament_id: nil)
    canceled = ifpa_events
      .where(start_date: @start_date..@end_date, end_date: @start_date..@end_date)
      .where.not(ifpa_tournament_id: seen_ids.to_a)
    @stats[:deleted_canceled] += canceled.delete_all

    # Events starting past the range were moved there or have mistyped years (e.g. 2109), and would otherwise stay
    # until they expire. A real one is imported again once it's within the range.
    @stats[:deleted_beyond_range] += ifpa_events.where(start_date: (@end_date + 1)..).delete_all
  end

  def add_error(message)
    @errors << message
    log(message)
  end

  def log(message)
    @logger&.info(message)
  end
end
