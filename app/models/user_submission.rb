class UserSubmission < ApplicationRecord
  has_paper_trail
  belongs_to :region, optional: true
  belongs_to :user, optional: true
  belongs_to :location, optional: true
  belongs_to :machine, optional: true

  scope :region, (->(name) { where(region_id: Region.find_by_name(name.downcase).id) })

  NEW_LMX_TYPE = 'new_lmx'.freeze
  CONTACT_US_TYPE = 'contact_us'.freeze
  NEW_CONDITION_TYPE = 'new_condition'.freeze
  REMOVE_MACHINE_TYPE = 'remove_machine'.freeze
  SUGGEST_LOCATION_TYPE = 'suggest_location'.freeze
  LOCATION_METADATA_TYPE = 'location_metadata'.freeze
  NEW_SCORE_TYPE = 'new_msx'.freeze
  CONFIRM_LOCATION_TYPE = 'confirm_location'.freeze
  DELETE_LOCATION_TYPE = 'delete_location'.freeze

  def user_email
    user ? user.email : ''
  end
end
