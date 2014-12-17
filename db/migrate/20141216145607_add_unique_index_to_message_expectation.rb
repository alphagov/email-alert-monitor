class AddUniqueIndexToMessageExpectation < ActiveRecord::Migration
  def change
    add_index :message_expectations, :content_id, unique: true
  end
end
