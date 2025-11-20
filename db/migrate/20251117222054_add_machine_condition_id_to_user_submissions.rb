class AddMachineConditionIdToUserSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :user_submissions, :machine_condition_id, :integer
  end
end
