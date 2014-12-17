module AsyncHelpers
  def eventually(options = {})
    timeout = options.fetch(:timeout, 2)
    interval = options.fetch(:interval, 0.1)
    time_limit = Time.now.utc + timeout
    begin
      yield
    rescue Exception => e
      raise if Time.now.utc >= time_limit
      sleep interval
      retry
    end
  end
end

RSpec.configuration.include(AsyncHelpers)
