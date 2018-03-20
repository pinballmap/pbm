class AddIfpaCalendarIdToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :ifpa_calendar_id, :integer
  end
end
