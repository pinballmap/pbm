class UserSubmission < ActiveRecord::Base
  belongs_to :region
  belongs_to :user

  attr_accessible :region_id, :submission_type, :submission, :user_id

  SUGGEST_LOCATION_TYPE = 'suggest_location'
  REMOVE_MACHINE_TYPE = 'remove_machine'
  CONTACT_US_TYPE = 'contact_us'
end
