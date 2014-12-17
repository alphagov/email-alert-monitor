
class RabbitmqConsumer
  class Message
    # @param delivery_info [Bunny::DeliveryInfo]
    # @param headers [Bunny::MessageProperties]
    # @param payload [String]
    def initialize(delivery_info, headers, payload)
      @delivery_info = delivery_info
      @headers = headers
      @body = payload
    end

    attr_reader :delivery_info, :headers, :body

    def body_data
      @body_data ||= JSON.parse(@body)
    end

    def ack
      @delivery_info.channel.ack(@delivery_info.delivery_tag)
    end

    def retry
      @delivery_info.channel.reject(@delivery_info.delivery_tag, true)
    end
  end

  # @param connection [Bunny::Session] The rabbitmq connection to use.
  # @param processor [#call] For each message received from the queue, this
  #   will be called with a corresponding instance of Message
  # @param config [Hash]
  # @option config [String] :queue The name of the queue to subscribe to.
  # @option config [Hash{String => String}] :bindings Hash of +exchange_name =>
  #   routing_key+ defining the exchanges to bind the queue to.
  def initialize(connection, processor, config)
    @queue_name = config.fetch(:queue)
    @bindings = config.fetch(:bindings, {})

    @processor = processor
    @connection = connection
  end

  def run
    queue.subscribe(:block => true, :manual_ack => true) do |delivery_info, headers, payload|
      begin
        @processor.call(Message.new(delivery_info, headers, payload))
      rescue Exception => e
        Rails.logger.warn "rabbitmq_consumer: aborting due to unhandled exception in processor #{e.class}: #{e.message}"
        Airbrake.notify_or_ignore(e,
          parameters: {
            delivery_info: delivery_info,
            properties: headers,
            payload: payload,
          }
        )
        # Exit to ensure that rabbitMQ requeues outstanding messages etc.
        # Rely on upstart to restart the worker.
        exit(1)
      end
    end
  end

  private

  def queue
    @queue ||= setup_queue
  end

  def setup_queue
    @channel = @connection.create_channel
    @channel.prefetch(1) # only one unacked message at a time
    queue = @channel.queue(@queue_name, :durable => true)
    @bindings.each do |exchange_name, routing_key|
      exchange = @channel.topic(exchange_name, :passive => true)
      queue.bind(exchange, :routing_key => routing_key)
    end
    queue
  end
end
