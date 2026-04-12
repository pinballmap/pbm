class AddIndexesToUserSubmissions < ActiveRecord::Migration[8.1]
  def self.up
    add_index :user_submissions, :submission_type
    add_index :user_submissions, :user_id
    add_index :user_submissions, :user_name
    add_index :user_submissions, :machine_id
    add_index :user_submissions, :location_id
    add_index :user_submissions, :deleted_at
    add_index :user_submissions, :created_at
    add_index :user_submissions, [:submission_type, :user_id]
    add_index :user_submissions, [:location_id, :submission_type]
  end

  def self.down
    remove_index :user_submissions, [:location_id, :submission_type]
    remove_index :user_submissions, [:submission_type, :user_id]
    remove_index :user_submissions, :created_at
    remove_index :user_submissions, :deleted_at
    remove_index :user_submissions, :location_id
    remove_index :user_submissions, :machine_id
    remove_index :user_submissions, :user_name
    remove_index :user_submissions, :user_id
    remove_index :user_submissions, :submission_type
  end
end
