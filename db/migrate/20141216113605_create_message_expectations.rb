class CreateMessageExpectations < ActiveRecord::Migration
  def change
    create_table :message_expectations do |t|
      t.text :content_id
      t.text :title
      t.text :base_path
      t.text :topics
      t.datetime :public_timestamp
      t.datetime :current_timestamp

      t.timestamps
    end
  end
end
