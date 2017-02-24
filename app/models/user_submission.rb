class UserSubmission < ActiveRecord::Base
  belongs_to :region
  belongs_to :user
  belongs_to :location
  belongs_to :machine

  attr_accessible :region_id, :user, :user_id, :submission_type, :submission, :location, :location_id, :machine, :machine_id

  scope :region, ->(name) { where(region_id: Region.find_by_name(name.downcase).id) }

  NEW_LMX_TYPE = 'new_lmx'
  CONTACT_US_TYPE = 'contact_us'
  NEW_CONDITION_TYPE = 'new_condition'
  REMOVE_MACHINE_TYPE = 'remove_machine'
  SUGGEST_LOCATION_TYPE = 'suggest_location'
  LOCATION_METADATA_TYPE = 'location_metadata'
  NEW_SCORE_TYPE = 'new_msx'
  CONFIRM_LOCATION_TYPE = 'confirm_location'

  def user_email
    user ? user.email : ''
  end
end
