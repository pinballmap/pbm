class AddTimestampsToSuggestedLocation < ActiveRecord::Migration
  def change
    add_column :suggested_locations, :created_at, :datetime
    add_column :suggested_locations, :updated_at, :datetime
  end
end
