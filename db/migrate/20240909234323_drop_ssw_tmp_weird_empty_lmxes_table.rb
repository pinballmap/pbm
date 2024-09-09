class DropSswTmpWeirdEmptyLmxesTable < ActiveRecord::Migration[7.1]
  def change
    drop_table :ssw_tmp_weird_empty_lmxes, if_exists: true
    drop_table :ssw_lpx_backup, if_exists: true
  end
end
