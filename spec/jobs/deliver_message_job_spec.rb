require 'rails_helper'

RSpec.describe DeliverMessageJob do
  let(:success_response) {{ "message_id" => "b7871749-bbd3-4cc5-95b9-182a88857a20" }}
  let(:message) { create(:message) }

  Sidekiq::Testing.inline! do
    context 'when retries have been exhausted' do
      let(:msg) do
        {
          'class' => 'Errors::BadGateway',
          'args' => "provider_one,#{message.id}",
          'error_message' => 'StandardError'
        }
      end

      it 'marks the message as external_request_failed' do
        described_class.sidekiq_retries_exhausted_block.call(msg)

        expect(message.reload.external_request_failed?).to be(true)
      end
    end

    context 'when requesting first delivery from provider one' do
      it 'triggers request to provider one' do
        expect(ProviderOneClient)
          .to receive(:post)
          .with(to_number: message.phone_number.value, message: message.body)
          .and_return(success_response)

        described_class.new.perform('provider_one', message.id)
        expect(message.reload.external_id).to eq(success_response['message_id'])
      end

      context 'when provider one request fails' do
        it 'triggers request to provider two' do
          expect(ProviderOneClient)
            .to receive(:post)
            .with(to_number: message.phone_number.value, message: message.body)
            .and_raise(Errors::BadGateway)
          expect(ProviderTwoClient)
            .to receive(:post)
            .with(to_number: message.phone_number.value, message: message.body)
            .and_return(success_response)

          described_class.new.perform('provider_one', message.id)
          expect(message.reload.external_id).to eq(success_response['message_id'])
        end
      end

      context 'when both providers fail' do
        it 'allows the error to be raised so the job retries' do
          expect(ProviderOneClient)
            .to receive(:post)
            .with(to_number: message.phone_number.value, message: message.body)
            .and_raise(Errors::BadGateway)
          expect(ProviderTwoClient)
            .to receive(:post)
            .with(to_number: message.phone_number.value, message: message.body)
            .and_raise(Errors::BadGateway)

          expect {
            described_class.new.perform('provider_one', message.id)
          }.to raise_error(
            Errors::BadGateway,
            'A third party request was not successful'
          )
        end
      end
    end

    context 'when requesting first delivery from provider two' do
      it 'triggers request to provider one' do
        expect(ProviderTwoClient)
          .to receive(:post)
          .with(to_number: message.phone_number.value, message: message.body)
          .and_return(success_response)

        described_class.new.perform('provider_two', message.id)
        expect(message.reload.external_id).to eq(success_response['message_id'])
      end

      context 'when provider one request fails' do
        it 'triggers request to provider two' do
          expect(ProviderTwoClient)
            .to receive(:post)
            .with(to_number: message.phone_number.value, message: message.body)
            .and_raise(Errors::BadGateway)
          expect(ProviderOneClient)
            .to receive(:post)
            .with(to_number: message.phone_number.value, message: message.body)
            .and_return(success_response)

          described_class.new.perform('provider_two', message.id)
          expect(message.reload.external_id).to eq(success_response['message_id'])
        end
      end

      context 'when both providers fail' do
        it 'allows the error to be raised so the job retries' do
          expect(ProviderTwoClient)
            .to receive(:post)
            .with(to_number: message.phone_number.value, message: message.body)
            .and_raise(Errors::BadGateway)
          expect(ProviderOneClient)
            .to receive(:post)
            .with(to_number: message.phone_number.value, message: message.body)
            .and_raise(Errors::BadGateway)

          expect {
            described_class.new.perform('provider_two', message.id)
          }.to raise_error(
            Errors::BadGateway,
            'A third party request was not successful'
          )
        end
      end
    end

    context 'when provider is not recognized' do
      let(:provider_name) { 'unrecognized_provider' }

      it 'raises an error' do
        expect { described_class.new.perform(provider_name, message.id) }
          .to raise_error(
            Errors::UnrecognizedProvider,
            "You must pass in one of the two recognized providers:"\
            " [provider_one, provider_two]"
          )
      end
    end
  end
end
