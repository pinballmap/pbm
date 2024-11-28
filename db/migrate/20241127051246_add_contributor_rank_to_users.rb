class AddContributorRankToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :contributor_rank, :string
  end
end
