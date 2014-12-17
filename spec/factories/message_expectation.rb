FactoryGirl.define do
  factory :message_expectation do
    content_id { SecureRandom.uuid }
    sequence(:title) { |n| "Title of entry #{n}" }
    base_path { "/#{title.parameterize}" }
    topics { "#{title.parameterize},#{title.parameterize}" }
    public_timestamp Time.zone.now
  end
end
