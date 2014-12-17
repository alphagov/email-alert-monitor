require 'rabbitmq_consumer'

class MessageQueueConsumer

  def self.run
    config = YAML.load_file(Rails.root.join('config', 'rabbitmq.yml'))[Rails.env]

    new(config).run
  end

  def initialize(config)
    @config = config.with_indifferent_access
    connection = Bunny.new(@config[:connection].symbolize_keys)
    connection.start
    consumer_config = {
      :queue => @config.fetch(:queue),
      :bindings => {
        @config.fetch(:exchange) => "#",
      },
    }
    processor = HeartbeatMiddlewareProcessor.new(Processor.new)
    @rmq_consumer = RabbitmqConsumer.new(connection, processor, consumer_config)
  end

  def run
    @rmq_consumer.run
  end

  class HeartbeatMiddlewareProcessor
    def initialize(next_processor)
      @next_processor = next_processor
    end

    def call(message)
      # Ignore heartbeat messages
      if message.headers.content_type == "application/x-heartbeat"
        message.ack
      else
        @next_processor.call(message)
      end
    end
  end

  class Processor

    def call(message)
      content_id = message.body_data["content_id"]
      # Ignore non-english items until a more nuanced approach can be created.
      if content_id.present? && message.body_data["locale"] == "en" && message.body_data["update_type"] == "major"
        expected_message = MessageExpectation.find_or_initialize_by(content_id: content_id)
        expected_message.update_attributes!(
          title: message.body_data["title"],
          base_path: message.body_data["base_path"],
          topics: message_topics(message),
          public_timestamp: message.body_data["public_updated_at"],
          current_timestamp: Time.zone.now
        )
      end
      message.ack
    rescue PG::UniqueViolation
      message.retry
    end

  private

    def message_topics(message)
      if message.body_data["details"].has_key?("tags") && message.body_data["details"].fetch("tags").has_key?("topics")
        message.body_data["details"].fetch("tags").fetch("topics").join(',')
      end
    end
  end
end
