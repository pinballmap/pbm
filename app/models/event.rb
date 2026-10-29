class Event < ApplicationRecord
  belongs_to :region, optional: true
  belongs_to :location, optional: true

  # Events at a location take its coordinates (the importer sets them for IFPA events). Unmatched IFPA events take
  # IFPA's, and other manually added ones geocode their address.
  geocoded_by :address, latitude: :latitude, longitude: :longitude
  before_save :set_manual_coordinates, if: -> { ifpa_tournament_id.nil? }

  # How long to keep showing an event after it ends when we don't know the viewer's date,
  # since events are in local dates around the world
  UPCOMING_GRACE_DAYS = 2
  # Events are deleted once they ended (or started, with no end date) this long ago
  EXPIRE_AFTER = 1.week

  scope :region, ->(name) { where(region_id: Region.find_by_name(name.downcase).id).to_a }
  scope :upcoming, ->(date = Date.current - UPCOMING_GRACE_DAYS) { where(end_date: date..).or(where(end_date: nil, start_date: date..)).reorder(:start_date, :name, :id) }
  scope :expired, ->(cutoff = Date.current - EXPIRE_AFTER) { where(end_date: ...cutoff).or(where(end_date: nil, start_date: ...cutoff)) }

  def active?
    if start_date && !end_date
      (start_date >= Date.today - 1.week)
    elsif end_date
      (end_date >= Date.today - 1.week)
    else
      1
    end
  end

  private

  def set_manual_coordinates
    if location
      self.latitude, self.longitude = location.lat, location.lon if will_save_change_to_location_id? || latitude.nil? || longitude.nil?
    elsif address.blank?
      self.latitude = self.longitude = nil
    elsif !ENV["SKIP_GEOCODE"] && (will_save_change_to_address? || will_save_change_to_location_id? || latitude.nil? || longitude.nil?)
      # Clear first so a failed lookup doesn't leave the old address's coordinates
      self.latitude = self.longitude = nil
      geocode
    end
  end
end
