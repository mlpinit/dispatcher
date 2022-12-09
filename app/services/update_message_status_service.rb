class UpdateMessageStatusService
  RECOGNIZED_STATUSES = %w{
    delivered
    failed
    invalid
  }

  EXTERNAL_TO_INTERNAL_STATUS_MAP = {
    'delivered' => 'delivered',
    'failed' => 'failed',
    'invalid' => 'undeliverable'
  }
  private_constant :EXTERNAL_TO_INTERNAL_STATUS_MAP

  def initialize(status:, message_external_id:)
    @status = status
    @message_external_id = message_external_id
  end

  def run
    raise Errors::MessageWithGivenExternalIdNotFound
      .new(external_id: message_external_id) if message.blank?
    raise Errors::MessageStatusNotRecognized
      .new(provided_status: status) unless RECOGNIZED_STATUSES.include?(status)

    message.update!(current_status: local_status)
    message.phone_number.update!(can_receive_messages: false) if undeliverable?
  end

  private

  attr_reader :status, :message_external_id

  def message
    @message ||= Message.find_by(external_id: message_external_id)
  end

  def local_status
    EXTERNAL_TO_INTERNAL_STATUS_MAP[status]
  end

  def undeliverable?
    local_status == 'undeliverable'
  end
end
