class AddOpdbImgHeightToMachine < ActiveRecord::Migration[5.2]
  def change
    add_column :machines, :opdb_img_height, :integer
  end
end
