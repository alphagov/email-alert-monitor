require 'bunny'
require 'childprocess'

module MessageQueueHelpers

  def put_message_on_queue(message_data)
    routing_key = "#{message_data["format"]}.#{message_data["update_type"]}"
    MessageQueueHelpers.exchange.publish(
      message_data.to_json,
      :routing_key => routing_key,
      :content_type => 'application/json',
    )
  end

  class << self
    def exchange
      @exchange ||= channel.topic(config[:exchange], :passive => true)
    end

    def channel
      @channel ||= connection.create_channel
    end

    def connection
      @connection ||= Bunny.new(config[:connection].symbolize_keys).start
    end

    def config
      @config ||= YAML.load_file(Rails.root.join('config', 'rabbitmq.yml'))[Rails.env].symbolize_keys
    end

    def included(base)
      base.extend(ExampleGroupMethods)
    end
  end

  module ExampleGroupMethods
    def start_message_consumer_around_all
      process = nil

      before :all do
        puts "Starting message consumer"
        ChildProcess.posix_spawn = true
        r, w = IO.pipe
        process = ChildProcess.build("ruby", "-S", "bundle", "exec", "rake", "message_queue:consumer")
        process.io.stdout = w
        process.leader = true
        process.start
        r.readline # Rails has booted in child app when this returns
        sleep 1 # extra sleep to allow queue to be created

      end

      after :all do
        if process && process.alive?
          puts "Stopping message consumer"
          process.stop
        end
      end
    end
  end
end

RSpec.configuration.include(MessageQueueHelpers, :message_queue)
