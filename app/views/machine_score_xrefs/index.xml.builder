xml.instruct! :xml, version: '1.0'
xml.data do
  xml.items do
    @msxs.each do |msx|
      xml.item do
        xml.title "#{msx.location.name}'s #{msx.machine.name}: #{msx.score} by #{msx.user ? msx.user.username : 'Unknown'} on #{msx.created_at.strftime('%d-%b-%Y')}"
        xml.description "#{msx.location.name}'s #{msx.machine.name}: #{msx.score} by #{msx.user ? msx.user.username : 'Unknown'} on #{msx.created_at.strftime('%d-%b-%Y')}"
      end
    end
  end
end
