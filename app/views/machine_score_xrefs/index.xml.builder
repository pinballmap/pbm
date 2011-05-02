xml.instruct! :xml, :version => "1.0"
xml.data do
  xml.items do
    for msx in @msxs
      xml.item do
        xml.title "#{msx.location.name}'s #{msx.machine.name}: #{MachineScoreXref::ENGLISH_SCORES[msx.rank]}, with #{msx.score} by #{msx.user.initials} on #{msx.created_at.strftime("%d-%b-%Y")}"
        xml.description "#{msx.location.name}'s #{msx.machine.name}: #{MachineScoreXref::ENGLISH_SCORES[msx.rank]}, with #{msx.score} by #{msx.user.initials} on #{msx.created_at.strftime("%d-%b-%Y")}"
      end
    end
  end
end
