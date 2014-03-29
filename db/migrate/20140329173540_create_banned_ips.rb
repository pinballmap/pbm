class CreateBannedIps < ActiveRecord::Migration
  def change
    create_table :banned_ips do |t|

      t.timestamps
    end
  end
end
