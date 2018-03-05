class AddLastUpdatedByUserIdToLocation < ActiveRecord::Migration[4.2]
  def change
    add_column :locations, :last_updated_by_user_id, :integer
  end
end
