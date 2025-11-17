class AddMachineScoreXrefIdToUserSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :user_submissions, :machine_score_xref_id, :integer
  end
end
