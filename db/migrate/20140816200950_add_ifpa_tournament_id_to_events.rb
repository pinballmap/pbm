class AddIfpaTournamentIdToEvents < ActiveRecord::Migration
  def change
    add_column :events, :ifpa_tournament_id, :integer
  end
end
