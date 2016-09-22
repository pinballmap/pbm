class RemoveLocationMachineXrefIdFromUserSubmissions < ActiveRecord::Migration
  def change
    remove_column :user_submissions, :location_machine_xref_id, :integer
  end
end
