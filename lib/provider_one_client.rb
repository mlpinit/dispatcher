module ProviderOneClient
  extend ProviderBaseClient

  def self.provider_endpoint
    Rails.application.credentials.sms_provider_one
  end
end
