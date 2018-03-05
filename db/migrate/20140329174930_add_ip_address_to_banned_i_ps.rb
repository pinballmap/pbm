class AddIpAddressToBannedIPs < ActiveRecord::Migration[4.2]
  def change
    add_column :banned_ips, :ip_address, :string
  end
end
