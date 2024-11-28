class FixUsersTableDefaultsAgain < ActiveRecord::Migration[7.2]
  def change
    change_column_null :users, :num_machines_added, false
    change_column_null :users, :num_machines_removed, false
    change_column_null :users, :num_locations_suggested, false
    change_column_null :users, :num_lmx_comments_left, false
    change_column_null :users, :num_msx_scores_added, false
    change_column_null :users, :user_submissions_count, false
    change_column_default :users, :num_machines_added, from: nil, to: 0
    change_column_default :users, :num_machines_removed, from: nil, to: 0
    change_column_default :users, :num_locations_suggested, from: nil, to: 0
    change_column_default :users, :num_lmx_comments_left, from: nil, to: 0
    change_column_default :users, :num_msx_scores_added, from: nil, to: 0
    change_column_default :users, :user_submissions_count, from: nil, to: 0
  end
end
