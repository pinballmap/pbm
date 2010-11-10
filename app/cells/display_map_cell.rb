class DisplayMapCell < Cell::Rails

  def display
    @locations = @opts[:locations]
    render
  end

end
