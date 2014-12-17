require 'rails_helper'

describe "Consuming messages from the publishing-api message queue", :message_queue do

  start_message_consumer_around_all

  context "for a major change" do
    let(:message_data) {
      {
        "base_path" => "/vat-rates",
        "content_id" => SecureRandom.uuid,
        "title" => "VAT rates",
        "locale" => "en",
        "public_updated_at" => "2014-05-14T13:00:06Z",
        "update_type" => "major",
        "details" => {
          "tags" => {
            "topics" => ["example topic1","example topic2"]
          }
        },
      }
    }

    it "creates a message expectation for the content item" do
      put_message_on_queue(message_data)

      eventually do
        expect(MessageExpectation.count).to eq(1)
        me = MessageExpectation.find_by!(content_id: message_data['content_id'])

        expect(me).to be
        expect(me.title).to eq('VAT rates')
        expect(me.base_path).to eq('/vat-rates')
        expect(me.topics).to eq('example topic1,example topic2')
        expect(me.public_timestamp).to eq('2014-05-14T13:00:06Z')
      end
    end

    it "updates an entry with a matching content Id" do
      message_expectation = create(:message_expectation,
        content_id: message_data["content_id"],
        title: "Old VAT rates",
        base_path: "/vat-rates",
        topics: 'example topic1,example topic2',
        public_timestamp: '2014-05-14T13:00:06Z',
      )

      put_message_on_queue(message_data)

      eventually do
        message_expectation.reload
        expect(message_expectation.title).to eq("VAT rates")
      end
    end
  end

  context "for a non major change" do
    let(:non_major_message_data) {
      {
        "base_path" => "/vat-rates",
        "content_id" => SecureRandom.uuid,
        "title" => "VAT rates",
        "locale" => "en",
        "public_updated_at" => "2014-05-14T13:00:06Z",
        "update_type" => "minor",
        "details" => {
          "tags" => {
            "topics" => ["example topic1","example topic2"]
          }
        },
      }
    }

    it "does not create a message expectation for the content item" do
      put_message_on_queue(non_major_message_data)

      eventually do
        expect(MessageExpectation.count).to eq(0)
      end
    end
  end
end
