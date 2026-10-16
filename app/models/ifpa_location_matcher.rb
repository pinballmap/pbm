# Associates an IFPA tournament (a hash from IFPA's /tournament/search results) with a PBM Location.
#
# Candidates are PBM locations within SEARCH_KM of IFPA's coordinates. Each candidate is checked against:
#   :zip_proximity - same zip and very close coordinates (a sturdier version of the old lat/lon/zip match)
#   :address       - same house number (from raw_address if address1 lacks one), similar street name, and same city or zip
#   :name          - IFPA's location_name (often blank) is similar to the PBM name, and the coordinates are close
#
# If one candidate passes, it's the match. If several do, the one passing the most checks wins;
# a tie means no match, since a wrong location is worse than none.
class IfpaLocationMatcher
  SEARCH_KM = 1.0
  ZIP_PROXIMITY_KM = 0.075
  NAME_KM = 0.15
  STREET_SIMILARITY = 0.6
  NAME_SIMILARITY = 0.4

  STREET_WORDS = {
    "avenue" => "ave", "av" => "ave", "boulevard" => "blvd", "circle" => "cir", "court" => "ct", "drive" => "dr",
    "expressway" => "expy", "freeway" => "fwy", "highway" => "hwy", "lane" => "ln", "parkway" => "pkwy",
    "place" => "pl", "plaza" => "plz", "road" => "rd", "route" => "rte", "square" => "sq", "street" => "st",
    "terrace" => "ter", "trail" => "trl",
    "north" => "n", "south" => "s", "east" => "e", "west" => "w",
    "northeast" => "ne", "northwest" => "nw", "southeast" => "se", "southwest" => "sw"
  }.freeze
  # Countries that write the house number before the street. Elsewhere it may trail the street name, as in much of Europe.
  LEADING_NUMBER_COUNTRIES = %w[US CA GB IE AU NZ].freeze
  UNIT_PATTERN = /\b(suite|ste|unit|apt|bldg|building|fl|floor|rm|room|space|spc)\b.*\z/

  Result = Data.define(:location, :methods, :distance_km, :ambiguous_location_ids)

  def self.match(tournament)
    new(tournament).match
  end

  def initialize(tournament)
    @t = tournament
    @lat = Float(tournament["latitude"], exception: false)
    @lon = Float(tournament["longitude"], exception: false)
    @trailing_numbers = !LEADING_NUMBER_COUNTRIES.include?(tournament["country_code"].to_s.upcase)
    @number, @street = self.class.split_street(tournament["address1"], trailing_numbers: @trailing_numbers)
    @number ||= number_from_raw_address
    @city = self.class.normalize(tournament["city"])
    @zip = self.class.normalize_zip(tournament["postal_code"])
    @name = self.class.normalize_name(tournament["location_name"])
  end

  def match
    return no_match unless @lat && @lon && !(@lat.zero? && @lon.zero?)

    hits = candidates.filter_map do |l|
      methods = methods_for(l)
      [ l, methods ] if methods.any?
    end
    return no_match if hits.empty?

    most = hits.map { |_, methods| methods.size }.max
    best = hits.select { |_, methods| methods.size == most }
    return no_match(ambiguous_location_ids: hits.map { |l, _| l.id }) if best.size > 1

    location, methods = best.first
    Result.new(location: location, methods: methods, distance_km: location.distance.to_f.round(3), ambiguous_location_ids: [])
  end

  private

  def candidates
    scope = Location.near([ @lat, @lon ], SEARCH_KM, units: :km)
    country = @t["country_code"].presence
    country ? scope.where("locations.country IS NULL OR locations.country = '' OR upper(locations.country) = ?", country.upcase) : scope
  end

  def methods_for(location)
    distance = location.distance.to_f
    zip_match = @zip.present? && @zip == self.class.normalize_zip(location.zip)
    methods = []

    methods << :zip_proximity if zip_match && distance <= ZIP_PROXIMITY_KM

    if @number
      number, street = self.class.split_street(location.street, trailing_numbers: @trailing_numbers)
      city_match = @city.present? && @city == self.class.normalize(location.city)
      if number == @number && self.class.similarity(street, @street) >= STREET_SIMILARITY && (city_match || zip_match)
        methods << :address
      end
    end

    if @name.present? && distance <= NAME_KM && self.class.similarity(self.class.normalize_name(location.name), @name) >= NAME_SIMILARITY
      methods << :name
    end

    methods
  end

  # Some tournaments leave the house number out of address1 ("E Spring St") but have it in raw_address,
  # which can also hold a venue name: "I Need a Miracle Tickets\r\n5541 E Spring St, Long Beach, CA 90808, US".
  # Search results replace that line break with two spaces: "I Need a Miracle Tickets  5541 E Spring St, ..."
  def number_from_raw_address
    return if @street.blank?

    @t["raw_address"].to_s.split(/[\r\n,]+|\s{2,}/).each do |part|
      number, street = self.class.split_street(part, trailing_numbers: @trailing_numbers)
      return number if number && self.class.similarity(street, @street) >= STREET_SIMILARITY
    end
    nil
  end

  def no_match(ambiguous_location_ids: [])
    Result.new(location: nil, methods: [], distance_km: nil, ambiguous_location_ids: ambiguous_location_ids)
  end

  class << self
    def normalize(str)
      I18n.transliterate(str.to_s).downcase.gsub(/[^a-z0-9]+/, " ").squish
    end

    def normalize_name(str)
      normalize(str).delete_prefix("the ")
    end

    # US zips compare on their first 5 digits; elsewhere just ignore case and spaces
    def normalize_zip(str)
      zip = str.to_s.upcase.delete(" ")
      zip.match?(/\A\d{5}(-?\d{4})?\z/) ? zip[0, 5] : zip
    end

    def normalize_street(str)
      # "N.E." would otherwise become "n e"
      street = str.to_s.sub(/#.*\z/, "").gsub(/\b([NSEW])\.\s?([EW])\b\.?/i, '\1\2')
      street = normalize(street).sub(UNIT_PATTERN, "")
      street.split.map { |word| STREET_WORDS.fetch(word, word) }.join(" ")
    end

    # Returns [house_number, street_name], or [nil, street] when there's no house number.
    # Trailing numbers are only considered where requested, so "Highway 99" isn't read as house number 99 in the US.
    def split_street(str, trailing_numbers: false)
      street = normalize_street(str)
      if (m = street.match(/\A(\d+[a-z]?) (.+)\z/))
        [ m[1], m[2] ]
      elsif trailing_numbers && (m = street.match(/\A(.+?) (\d+[a-z]?)\z/))
        [ m[2], m[1] ]
      else
        [ nil, street ]
      end
    end

    # Approximates pg_trgm's similarity(): shared trigrams over all trigrams, words padded with spaces
    def similarity(a, b)
      ta = trigrams(a)
      tb = trigrams(b)
      return 0.0 if ta.empty? || tb.empty?

      (ta & tb).size.to_f / (ta | tb).size
    end

    def trigrams(str)
      str.to_s.split.flat_map { |word| "  #{word} ".chars.each_cons(3).map(&:join) }.to_set
    end
  end
end
