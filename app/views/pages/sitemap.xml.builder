xml.instruct!
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  [ "/", "/map", "/app", "/faq", "/store", "/donate" ].each do |path|
    xml.url { xml.loc "#{@base_url}#{path}" }
  end

  @regions.each do |id, name|
    xml.url do
      xml.loc "#{@base_url}/#{name}"
      xml.lastmod @region_lastmods[id].iso8601 if @region_lastmods[id]
    end
  end

  @locations.each do |id, date_last_updated|
    xml.url do
      xml.loc "#{@base_url}/map?by_location_id=#{id}"
      xml.lastmod date_last_updated.iso8601 if date_last_updated
    end
  end

  @machines.each do |id, lastmod|
    xml.url do
      xml.loc "#{@base_url}/map?by_machine_id=#{id}"
      xml.lastmod lastmod.to_date.iso8601 if lastmod
    end
  end
end
