class MessagesController < ApplicationController
  protect_from_forgery with: :null_session

  rescue_from *[
    ActionController::ParameterMissing,
    ActiveRecord::RecordInvalid,
    Errors::InvalidPhoneNumber
  ], with: :handle_bad_request
  rescue_from *[
    Errors::PhoneNumberCannotReceiveMessages,
    Errors::MessageWithGivenExternalIdNotFound,
    Errors::MessageStatusNotRecognized
  ], with: :handle_unprocessable_requests

  def create
    DeliverMessageService.new(
      to_number: params.require(:to_number),
      message_body: params.require(:message)
    ).run

    render status: 202, json: {
      message: 'Delivery request received and it will be processed async.'
    }
  end

  def delivery_status
    UpdateMessageStatusService.new(
      status: params.require(:status),
      message_external_id: params.require(:message_id)
    ).run
  end

  private

  def handle_bad_request(error)
    render status: 400, json: { message: error.message.lines.first.strip }
  end

  def handle_unprocessable_requests(error)
    render status: 422, json: { message: error.message }
  end
end
