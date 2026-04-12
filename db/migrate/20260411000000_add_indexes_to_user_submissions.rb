class AddIndexesToUserSubmissions < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_index :user_submissions, :submission_type, algorithm: :concurrently
    add_index :user_submissions, :user_id, algorithm: :concurrently
    add_index :user_submissions, :user_name, algorithm: :concurrently
    add_index :user_submissions, :machine_id, algorithm: :concurrently
    add_index :user_submissions, :location_id, algorithm: :concurrently
    add_index :user_submissions, :deleted_at, algorithm: :concurrently
    add_index :user_submissions, :created_at, algorithm: :concurrently
    add_index :user_submissions, [:submission_type, :user_id], algorithm: :concurrently
    add_index :user_submissions, [:location_id, :submission_type], algorithm: :concurrently
  end

  def down
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
