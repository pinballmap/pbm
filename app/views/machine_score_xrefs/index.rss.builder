xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title "#{@region ? @region.full_name + ' ' : ''}Pinball Map - New Score List"
    xml.description "Recent High Scores!"
    xml.link [ request.protocol, request.host_with_port ].join("")

    @msxs.each do |msx|
      machine = msx.machine
      location = msx.location
      xml.item do
        xml.title "#{msx.machine_name} at #{msx.location_name}: #{number_with_precision(msx.high_score, precision: 0, delimiter: ',')} by #{msx.user_name.nil? ? 'Unknown' : msx.user_name} on #{msx.created_at.to_fs(:rfc822)}"
        xml.link [ request.protocol, request.host_with_port, @region ? region_homepage_path(@region.name.downcase) : "/map", "/?by_location_id=#{msx.location_id}" ].join("")
        xml.description "Added on #{msx.created_at.nil? ? 'UNKNOWN' : msx.created_at.to_fs(:rfc822)}"
        xml.guid msx.id, isPermaLink: false
        xml.pubDate msx.created_at.nil? ? "UNKNOWN" : msx.created_at.to_fs(:rfc822)
      end
    end
  end
end
