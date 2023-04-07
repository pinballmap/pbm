class Event < ApplicationRecord
  has_paper_trail
  belongs_to :region, optional: true
  belongs_to :location, optional: true

  default_scope { order :id }

  scope :region, (->(name) { where(region_id: Region.find_by_name(name.downcase).id).to_a })

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
