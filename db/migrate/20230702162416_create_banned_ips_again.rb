class CreateBannedIpsAgain < ActiveRecord::Migration[7.0]
  def change
    create_table :banned_ips, if_not_exists: true do |t|
      t.string :ip_address

      t.timestamps
    end
  end
end
