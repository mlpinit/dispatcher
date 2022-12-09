module ProviderTwoClient
  extend ProviderBaseClient

  def self.provider_endpoint
    Rails.application.credentials.sms_provider_two
  end
end
