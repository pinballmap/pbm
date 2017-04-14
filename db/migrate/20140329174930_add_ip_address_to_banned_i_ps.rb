class AddIpAddressToBannedIPs < ActiveRecord::Migration
  def change
    add_column :banned_ips, :ip_address, :string
  end
end
