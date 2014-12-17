RSpec.configure do |config|

  config.before(:suite) do
    DatabaseCleaner.clean_with :truncation
  end

  config.around :each do |example|
    if example.metadata[:message_queue]
      DatabaseCleaner.strategy = :truncation
    else
      DatabaseCleaner.strategy = :transaction
    end

    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
