RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.before(:suite) do
    ActiveRecord::Base.transaction do
      FactoryGirl.lint
      raise ActiveRecord::Rollback.new
    end
  end
end
