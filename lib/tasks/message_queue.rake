namespace :message_queue do

  desc "Run worker to consume messages from rabbitmq"
  task :consumer => :environment do
    require 'message_queue_consumer'
    # Note: this output is used in the test helpers to detect when this has started.
    puts "Starting message consumer"
    $stdout.flush
    begin
      MessageQueueConsumer.run
    rescue SignalException => e
      puts "Received #{e}: exiting..."
    end
  end
end
