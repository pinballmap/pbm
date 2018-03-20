class AddTimestampsToSuggestedLocation < ActiveRecord::Migration[4.2]
  def change
    add_column :suggested_locations, :created_at, :datetime
    add_column :suggested_locations, :updated_at, :datetime
  end
end
