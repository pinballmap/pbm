class AddMetaFieldsToUserSubmissions < ActiveRecord::Migration[4.2]
  def change
    add_column :user_submissions, :location_id, :integer
    add_column :user_submissions, :machine_id, :integer
    add_column :user_submissions, :location_machine_xref_id, :integer
  end
end
