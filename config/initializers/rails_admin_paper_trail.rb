RailsAdmin::Extensions::PaperTrail::VersionProxy.module_eval do
  def message
    if @version.event == "update"
        @message = @version.object_changes
    else
        @message = @version.event
    end
    @version.respond_to?(:changeset) && @version.changeset.present? ? @message + ' [' + @version.changeset.to_a.collect { |c| "#{c[0]} = #{c[1][1]}" }.join(', ') + ']' : @message
  end
end
