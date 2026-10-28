class AddRankingToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :ranking, :string
  end
end
