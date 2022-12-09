require "rails_helper"

RSpec.describe 'MessagesDeliveryStatus', type: :request do
  let(:headers) {
    {
      "CONTENT_TYPE" => "application/json",
      "ACCEPT" => "application/json"
    }
  }
  let(:body) { JSON.parse(response.body) }
  let(:message) { create(:message, :with_external_id) }

  context 'with missing status param' do
    it 'returns a bad request error message' do
      params = { message_id: message.external_id }
      post '/messages/delivery_status', params: params.to_json, headers: headers

      expect(response.status).to eq(400)
      expect(body['message']).to eq('param is missing or the value is empty: status')
    end
  end

  context 'with missing message_id param' do
    it 'returns a bad request error message' do
      params = { status: 'delivered' }
      post '/messages/delivery_status', params: params.to_json, headers: headers

      expect(response.status).to eq(400)
      expect(body['message']).to eq('param is missing or the value is empty: message_id')
    end
  end

  context "when message can't be found using external id" do
    let(:fake_external_message_id) { SecureRandom.uuid }

    it 'returns a 422' do
      params = { status: 'failed', message_id: fake_external_message_id }
      post '/messages/delivery_status', params: params.to_json, headers: headers

      expect(response.status).to eq(422)
      expect(body['message']).to eq("Could not find message with id: #{fake_external_message_id}")
    end
  end

  context 'when status is not recognized' do
    it 'returns a 422' do
      params = { status: 'unknown', message_id: message.external_id }
      post '/messages/delivery_status', params: params.to_json, headers: headers

      expect(response.status).to eq(422)
      expect(body['message']).to eq(
        "Expected one of: [delivered, failed, invalid] but received: unknown"
      )
    end
  end

  describe 'successful callback' do
    context 'when message is delivered' do
      it 'handles post request' do
        params = { status: 'delivered', message_id: message.external_id }
        post '/messages/delivery_status', params: params.to_json, headers: headers

        expect(response.status).to eq(204)
        expect(message.reload.delivered?).to be(true)
      end
    end

    context 'when phone number is invalid' do
      it 'handles post request' do
        params = { status: 'invalid', message_id: message.external_id }
        post '/messages/delivery_status', params: params.to_json, headers: headers

        expect(response.status).to eq(204)
        expect(message.reload.undeliverable?).to be(true)
      end
    end

    context 'when delivery failed' do
      it 'handles post request' do
        params = { status: 'failed', message_id: message.external_id }
        post '/messages/delivery_status', params: params.to_json, headers: headers

        expect(response.status).to eq(204)
        expect(message.reload.failed?).to be(true)
      end
    end
  end
end
