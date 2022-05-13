class DropBannedIpTable < ActiveRecord::Migration[5.2]
  def up
    drop_table :banned_ips
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
