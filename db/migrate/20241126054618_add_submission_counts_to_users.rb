class AddSubmissionCountsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :num_machines_added, :integer, default: 0
    add_column :users, :num_machines_removed, :integer, default: 0
    add_column :users, :num_locations_suggested, :integer, default: 0
    add_column :users, :num_lmx_comments_left, :integer, default: 0
    add_column :users, :num_msx_scores_added, :integer, default: 0
  end
end
