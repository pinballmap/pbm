class AddFieldsToUserSubmissions < ActiveRecord::Migration[6.1]
  def change
    add_column :user_submissions, :comment, :string
    add_column :user_submissions, :user_name, :string
    add_column :user_submissions, :location_name, :string
    add_column :user_submissions, :machine_name, :string
    add_column :user_submissions, :high_score, :bigint
  end
end
