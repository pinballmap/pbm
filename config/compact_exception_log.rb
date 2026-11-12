# Semantic Logger logs exceptions with their raw backtrace, bypassing Rails.backtrace_cleaner.
QUIET_EXCEPTIONS = [ ActionController::RoutingError, ActiveRecord::RecordNotFound ].freeze

COMPACT_EXCEPTION_LOG = lambda do |log|
  exception = log.exception
  next true unless exception

  lines = [ exception.message == exception.class.name ? exception.message : "#{exception.class}: #{exception.message}" ]
  # Bot noise: message only, no trace
  unless QUIET_EXCEPTIONS.any? { |klass| exception.is_a?(klass) }
    trace = Rails.backtrace_cleaner.clean(exception.backtrace || [])
    trace = Rails.backtrace_cleaner.clean(exception.backtrace || [], :noise) if trace.empty?
    lines.concat(trace.map { |line| "  #{line}" })
  end

  log.message = [ log.message.presence, lines.join("\n") ].compact.join(": ")
  log.exception = nil
  true
end
