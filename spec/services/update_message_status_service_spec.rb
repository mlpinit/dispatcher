require 'rails_helper'

RSpec.describe UpdateMessageStatusService do
  let(:message) { create(:message, :with_external_id) }

  context 'with unrecognized external id' do
    let(:unrecognized_external_id) { SecureRandom.uuid }

    it 'raises an error' do
      expect {
        described_class
          .new(status: 'delivered', message_external_id: unrecognized_external_id)
          .run
      }.to raise_error(
        Errors::MessageWithGivenExternalIdNotFound,
        "Could not find message with id: #{unrecognized_external_id}"
      )
    end
  end

  context 'with unrecognized status' do
    let(:unrecognized_status) { 'postponed' }

    it 'raises an error' do
      expect {
        described_class.new(
          status: unrecognized_status,
          message_external_id: message.external_id
        ).run
      }.to raise_error(
        Errors::MessageStatusNotRecognized,
        "Expected one of: [delivered, failed, invalid] but received: #{unrecognized_status}"
      )
    end
  end

  context 'with status delivered' do
    let(:status) { 'delivered' }

    it 'updates message current_status to delivered' do
      expect {
        described_class
        .new(status: status, message_external_id: message.external_id)
        .run
      }.to change { message.reload.current_status }.from('initiated').to('delivered')
    end
  end

  context 'with status failed' do
    let(:status) { 'failed' }

    it 'updates message current_status to failed' do
      expect {
        described_class
        .new(status: status, message_external_id: message.external_id)
        .run
      }.to change { message.reload.current_status }.from('initiated').to('failed')
    end
  end

  context 'with status invalid' do
    let(:status) { 'invalid' }

    it 'updates message current_status to undeliverable' do
      expect {
        described_class
        .new(status: status, message_external_id: message.external_id)
        .run
      }.to change { message.reload.current_status }.from('initiated').to('undeliverable')
    end

    it 'updates phone number can_receive_messages to false' do
      expect {
        described_class
        .new(status: status, message_external_id: message.external_id)
        .run
      }.to change { message.phone_number.reload.can_receive_messages }.from(true).to(false)
    end
  end
end
