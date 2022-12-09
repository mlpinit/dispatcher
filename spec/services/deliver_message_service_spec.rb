require 'rails_helper'

RSpec.describe DeliverMessageService do
  let(:message_body) { 'Hello World' }
  let(:phone_number) { '+13124683788' }

  context 'with invalid phone number' do
    let(:invalid_phone_number) { 'invlaid-fake-number' }

    it 'raises an error' do
      expect {
        described_class
          .new(to_number: invalid_phone_number, message_body: message_body)
          .run
      }.to raise_error(
        Errors::InvalidPhoneNumber,
        'Must be a valid US phone number'
      )
    end
  end

  context 'when phone number cannot receive messages' do
    let(:phone_number_unreceivable) { create(:phone_number, :unreceivable) }

    it 'raises an error' do
      expect {
        described_class
          .new(to_number: phone_number_unreceivable.value, message_body: message_body)
          .run
      }.to raise_error(
        Errors::PhoneNumberCannotReceiveMessages,
        'Our SMS providers are not able to deliver a message to this number'
      )
    end
  end

  context 'when message is longer than 160 characters' do
    let(:message_body) { 161.times.map { 'a' }.join }

    it 'raises an error' do
      expect {
        described_class
          .new(to_number: phone_number, message_body: message_body)
          .run
      }.to raise_error(
        ActiveRecord::RecordInvalid,
        "Validation failed: Body is too long (maximum is 160 characters)"
      )
    end
  end

  context 'when message is blank' do
    let(:message_body) { '' }

    it 'raises an error' do
      expect {
        described_class
          .new(to_number: phone_number, message_body: message_body)
          .run
      }.to raise_error(
        ActiveRecord::RecordInvalid,
        "Validation failed: Body can't be blank"
      )
    end
  end

  context 'when sms provider delivery can be scheduled' do
    it 'enqueues a message delivery job' do
      expect {
        described_class
          .new(to_number: phone_number, message_body: message_body)
          .run
      }.to change { DeliverMessageJob.jobs.count }.by(1)
    end
  end

  describe 'load balancer' do
    it 'balances ~30% of requests to provider 1 and ~70% of requests to provider 2' do
      srand(4321)

      expect(DeliverMessageJob)
        .to receive(:perform_async)
        .with('provider_one', any_args)
        .exactly(33)
        .times

      expect(DeliverMessageJob)
        .to receive(:perform_async)
        .with('provider_two', any_args)
        .exactly(67)
        .times

      100.times do
        described_class
          .new(to_number: phone_number, message_body: message_body)
          .run
      end
    end
  end
end
