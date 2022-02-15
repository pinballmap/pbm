class AddOpdbImgWidthToMachine < ActiveRecord::Migration[5.2]
  def change
    add_column :machines, :opdb_img_width, :integer
  end
end
