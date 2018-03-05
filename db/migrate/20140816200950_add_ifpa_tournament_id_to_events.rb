class AddIfpaTournamentIdToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :ifpa_tournament_id, :integer
  end
end
