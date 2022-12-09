class PhoneNumber < ApplicationRecord
  has_many :messages

  before_save :normalize_value

  validates :value, presence: true

  def normalize_value
    self.value = Phonelib.parse(value, 'US').full_e164
  end
end
