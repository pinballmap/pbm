class AddIfpaCalendarIdToEvents < ActiveRecord::Migration
  def change
    add_column :events, :ifpa_calendar_id, :integer
  end
end
