class LocationSearchCell < Cell::Rails
  def lookup
    @locations = @opts[:locations]
    render
  end
end
