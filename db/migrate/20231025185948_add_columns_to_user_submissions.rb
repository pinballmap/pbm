class AddColumnsToUserSubmissions < ActiveRecord::Migration[7.0]
  def change
    add_column :user_submissions, :lat, :float
    add_column :user_submissions, :lon, :float
  end
end
