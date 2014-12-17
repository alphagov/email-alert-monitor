class MessageExpectation < ActiveRecord::Base
  validates :content_id, uniqueness: true 
end
