class AddSubmissionCountsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :num_machines_added, :integer
    add_column :users, :num_machines_removed, :integer
    add_column :users, :num_locations_suggested, :integer
    add_column :users, :num_lmx_comments_left, :integer
    add_column :users, :num_msx_scores_added, :integer
  end
end
