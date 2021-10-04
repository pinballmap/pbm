class AddOpdbImgToMachine < ActiveRecord::Migration[5.2]
  def change
    add_column :machines, :opdb_img, :text
  end
end
