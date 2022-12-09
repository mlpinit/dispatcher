require 'rails_helper'

RSpec.describe ProviderTwoClient do
  let(:to_number) { '1234567777' }
  let(:message) { 'Hello World' }

  context 'when provider two responds with a 200' do
    it 'returns the external message id' do
      VCR.use_cassette("success-provider-two") do
        expect(described_class.post(to_number: to_number, message: message))
          .to eq({ "message_id" => "b7871749-bbd3-4cc5-95b9-182a88857a20" })
      end
    end
  end

  context 'when provider is offline' do
    it 'raises an error' do
      VCR.use_cassette("provider-two-is-down") do
        expect { described_class.post(to_number: to_number, message: message) }
          .to raise_error(
            Errors::BadGateway,
            'A third party request was not successful'
          )
      end
    end
  end
end
