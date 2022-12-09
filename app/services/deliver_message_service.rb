class DeliverMessageService
  def initialize(to_number:, message_body:)
    @to_number = to_number
    @message_body = message_body
  end

  def run
    raise Errors::InvalidPhoneNumber if sanitized_number.invalid?
    raise Errors::PhoneNumberCannotReceiveMessages unless phone_number.can_receive_messages?

    DeliverMessageJob.perform_async(provider_name, message.id)
  end

  private

  attr_reader :to_number, :message_body

  def sanitized_number
    @sanitized_number ||= Phonelib.parse(to_number, 'US')
  end

  def phone_number
    @phone_number ||= PhoneNumber.create_or_find_by!(value: sanitized_number.full_e164)
  end

  def message
    @message ||= phone_number.messages.create!(body: message_body)
  end

  def provider_name
    return 'provider_one' if rand(1..10) <= 3

    'provider_two'
  end
end
