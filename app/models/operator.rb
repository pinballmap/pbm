class Operator < ApplicationRecord
  has_paper_trail
  belongs_to :region, optional: true
  has_many :locations
  has_many :suggested_locations

  scope :region, ->(name) { where(region_id: Region.find_by_name(name.downcase).id) }

  def operator_has_email
    email.blank? ? false : true
  end

  before_save do
    Status.where(status_type: "operators").update({ updated_at: Time.current })
  end

  before_destroy do
    Status.where(status_type: "operators").update({ updated_at: Time.current })
  end

  def generate_operator_daily_digest
    start_of_day = (Time.now - 1.day).beginning_of_day
    end_of_day = (Time.now - 1.day).end_of_day

    { machine_comments: UserSubmission.joins(:location).where("user_submissions.created_at is not null and user_submissions.created_at > ? and user_submissions.created_at < ? and submission_type = ?", start_of_day, end_of_day, UserSubmission::NEW_CONDITION_TYPE).where(deleted_at: nil).where(location: { operator_id: self }).collect(&:submission),

    machines_added: UserSubmission.joins(:location).where("user_submissions.created_at is not null and user_submissions.created_at > ? and user_submissions.created_at < ? and submission_type = ?", start_of_day, end_of_day, UserSubmission::NEW_LMX_TYPE).where(deleted_at: nil).where(location: { operator_id: self }).collect(&:submission),

    machines_removed: UserSubmission.joins(:location).where("user_submissions.created_at is not null and user_submissions.created_at > ? and user_submissions.created_at < ? and submission_type = ?", start_of_day, end_of_day, UserSubmission::REMOVE_MACHINE_TYPE).where(deleted_at: nil).where(location: { operator_id: self }).collect(&:submission) }
  end
end
