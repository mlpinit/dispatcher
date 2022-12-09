module Errors
  class PhoneNumberCannotReceiveMessages < StandardError
    def message
      'Our SMS providers are not able to deliver a message to this number'
    end
  end

  class InvalidPhoneNumber < StandardError
    def message
      'Must be a valid US phone number'
    end
  end

  class BadGateway < StandardError
    def message
      'A third party request was not successful'
    end
  end

  class UnrecognizedProvider < StandardError
    def message
      "You must pass in one of the two recognized providers:"\
      " [provider_one, provider_two]"
    end
  end

  class MessageWithGivenExternalIdNotFound < StandardError
    def initialize(external_id:)
      @external_id = external_id
    end

    def message
      "Could not find message with id: #{external_id}"
    end

    private

    attr_reader :external_id
  end

  class MessageStatusNotRecognized < StandardError
    def initialize(provided_status:)
      @provided_status = provided_status
    end

    def message
      "Expected one of: [#{recognized_statuses}] but received: #{provided_status}"
    end

    private

    attr_reader :provided_status

    def recognized_statuses
      UpdateMessageStatusService::RECOGNIZED_STATUSES.join(', ')
    end
  end
end
