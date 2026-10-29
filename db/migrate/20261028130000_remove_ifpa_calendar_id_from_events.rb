class RemoveIfpaCalendarIdFromEvents < ActiveRecord::Migration[8.1]
  def change
    remove_index :events, :ifpa_calendar_id
    remove_column :events, :ifpa_calendar_id, :integer
  end
end
