# Semantic Logger logs exceptions with their raw backtrace, bypassing Rails.backtrace_cleaner.
COMPACT_EXCEPTION_LOG = lambda do |log|
  exception = log.exception
  next true unless exception

  wrapper = ActionDispatch::ExceptionWrapper.new(Rails.backtrace_cleaner, exception)
  lines = [ exception.message == exception.class.name ? exception.message : "#{exception.class}: #{exception.message}" ]
  unless wrapper.rescue_response?
    trace = wrapper.exception_trace
    # Some exceptions, like ActiveModel::MissingAttributeError, have no backtrace_locations for ExceptionWrapper to read
    if trace.empty? && exception.backtrace
      trace = Rails.backtrace_cleaner.clean(exception.backtrace)
      trace = Rails.backtrace_cleaner.clean(exception.backtrace, :noise) if trace.empty?
    end
    lines.concat(trace.map { |line| "  #{line}" })
  end

  log.message = [ log.message.presence, lines.join("\n") ].compact.join(": ")
  log.exception = nil
  true
end
