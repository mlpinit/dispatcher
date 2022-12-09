class DeliverMessageJob
  include Sidekiq::Job

  sidekiq_retries_exhausted do |msg, exception|
    message_id = msg['args'].split(',').second
    message = Message.find(message_id)
    message.external_request_failed!
  end

  def perform(provider_name, message_id)
    raise Errors::UnrecognizedProvider unless PROVIDERS.keys.include?(provider_name)

    message = Message.find(message_id)

    response = provider(provider_name).post(
      to_number: message.phone_number.value,
      message: message.body
    )
    message.update!(external_id: response['message_id'])
  rescue Errors::BadGateway
    response = provider_counterpart(provider_name).post(
      to_number: message.phone_number.value,
      message: message.body
    )
    message.update!(external_id: response['message_id'])
  end

  private

  def provider(provider_name)
    PROVIDERS[provider_name]
  end

  def provider_counterpart(provider_name)
    COUNTERPARTS[provider_name]
  end

  PROVIDERS = {
    'provider_one' => ProviderOneClient,
    'provider_two' => ProviderTwoClient
  }
  private_constant :PROVIDERS

  COUNTERPARTS = {
    'provider_one' => ProviderTwoClient,
    'provider_two' => ProviderOneClient,
  }
  private_constant :COUNTERPARTS
end
