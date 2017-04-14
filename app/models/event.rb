class Event < ActiveRecord::Base
  belongs_to :region
  belongs_to :location

  default_scope { order :id }

  scope :region, ->(name) { where(region_id: Region.find_by_name(name.downcase).id).to_a }

  attr_accessible :name, :long_desc, :start_date, :end_date, :region_id, :external_link, :category_no, :location_id, :category, :external_location_name, :ifpa_tournament_id, :ifpa_calendar_id

  def active?
    if start_date && !end_date
      (start_date >= Date.today - 1.week)
    elsif end_date
      (end_date >= Date.today - 1.week)
    else
      1
    end
  end
end
