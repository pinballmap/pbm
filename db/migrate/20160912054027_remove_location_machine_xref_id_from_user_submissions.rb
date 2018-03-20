class RemoveLocationMachineXrefIdFromUserSubmissions < ActiveRecord::Migration[4.2]
  def change
    remove_column :user_submissions, :location_machine_xref_id, :integer
  end
end
