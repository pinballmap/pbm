class UserSubmission < ActiveRecord::Base
  belongs_to :region
  belongs_to :user

  attr_accessible :region_id, :user, :user_id, :submission_type, :submission

  scope :region, ->(name) { where(region_id: Region.find_by_name(name.downcase).id) }

  SUGGEST_LOCATION_TYPE = 'suggest_location'
  REMOVE_MACHINE_TYPE = 'remove_machine'
  CONTACT_US_TYPE = 'contact_us'
end
