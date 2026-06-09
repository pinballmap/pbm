class Operator < ApplicationRecord
  has_paper_trail
  belongs_to :region, optional: true
  has_many :locations
  has_many :suggested_locations
  has_many :users

  scope :region, ->(name) { where(region_id: Region.find_by_name(name.downcase).id) }

  def operator_has_email
    email.blank? ? false : true
  end

  def digest_recipients
    (users.pluck(:email) << email).uniq
  end

  MOBILE_CACHE_KEY = "api/v1/operators/no_details"

  before_save do
    Status.where(status_type: "operators").update({ updated_at: Time.current })
  end

  before_destroy do
    Status.where(status_type: "operators").update({ updated_at: Time.current })
  end

  after_commit -> { Rails.cache.delete(MOBILE_CACHE_KEY) }

  def generate_operator_daily_digest
    start_of_day = (Time.now - 1.day).beginning_of_day
    end_of_day = (Time.now - 1.day).end_of_day

    submissions = UserSubmission.joins(:location)
      .where(created_at: start_of_day..end_of_day, deleted_at: nil)
      .where(location: { operator_id: self })

    to_item = ->(us) { { location_name: us.location_name, location_id: us.location_id, machine_name: us.machine_name, comment: us.comment, user_name: us.user_name } }

    {
      machine_comments: submissions.where(submission_type: UserSubmission::NEW_CONDITION_TYPE).order(:location_name).map(&to_item),
      machines_added:   submissions.where(submission_type: UserSubmission::NEW_LMX_TYPE).order(:location_name).map(&to_item),
      machines_removed: submissions.where(submission_type: UserSubmission::REMOVE_MACHINE_TYPE).order(:location_name).map(&to_item)
    }
  end
end
