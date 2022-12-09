class Message < ApplicationRecord
  enum :current_status, {
    initiated: 'initiated',
    delivered: 'delivered',
    failed: 'failed',
    undeliverable: 'undeliverable',
    external_request_failed: 'external_request_failed'
  }

  belongs_to :phone_number

  validates :body, presence: true
  validates :body, length: { maximum: 160 }
end
