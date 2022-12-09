require "rails_helper"

RSpec.describe 'Messages', type: :request do
  let(:headers) {
    {
      "CONTENT_TYPE" => "application/json",
      "ACCEPT" => "application/json"
    }
  }
  let(:message) { "Hello World" }
  let(:body) { JSON.parse(response.body) }
  let(:valid_phone_number) { '7039978823' }

  context 'when to_number is missing' do
    it 'returns a bad request status' do
      params = { message: message }
      post '/messages', params: params.to_json, headers: headers

      expect(response.status).to eq(400)
      expect(body['message']).to eq('param is missing or the value is empty: to_number')
    end
  end

  context 'when message is missing' do
    it 'returns a bad request status' do
      params = { to_number: valid_phone_number }
      post '/messages', params: params.to_json, headers: headers

      expect(response.status).to eq(400)
      expect(body['message']).to eq('param is missing or the value is empty: message')
    end
  end

  context 'when sending a message to a potentially valid number' do
    it 'returns a 202 with with a descriptive message' do
      params = { to_number: valid_phone_number, message: message }
      post '/messages', params: params.to_json, headers: headers

      expect(response.status).to eq(202)
      expect(body['message']).to eq('Delivery request received and it will be processed async.')
    end
  end

  context 'when message is too large' do
    let(:message) { 161.times.map { 'a' }.join }

    it 'returns a bad request status' do
      params = { to_number: valid_phone_number, message: message }
      post '/messages', params: params.to_json, headers: headers

      expect(response.status).to eq(400)
      expect(body['message']).to eq('Validation failed: Body is too long (maximum is 160 characters)')
    end
  end

  context 'when phone number cannot receive messages' do
    let(:phone_number) { create(:phone_number, :unreceivable) }

    it 'returns a 422' do
      params = { to_number: phone_number.value, message: message }
      post '/messages', params: params.to_json, headers: headers

      expect(response.status).to eq(422)
      expect(body['message']).to eq('Our SMS providers are not able to deliver a message to this number')
    end
  end
end
