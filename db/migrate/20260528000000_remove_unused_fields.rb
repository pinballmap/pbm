class RemoveUnusedFields < ActiveRecord::Migration[8.0]
  def change
    remove_column :machine_score_xrefs, :rank, :string
    remove_column :machines, :kineticist_url, :string
    remove_column :machines, :ipdb_link, :string
  end
end
