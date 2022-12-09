module ProviderBaseClient
  def post(to_number:, message:)
    response = conn.post do |req|
      req.body = {
        to_number: to_number,
        message: message,
        callback_url: callback_url
      }.to_json
    end

    raise Errors::BadGateway if response.status != 200

    JSON.parse(response.body)
  end

  private

  def conn
    Faraday.new(url: provider_endpoint, headers: headers)
  end

  def headers
    { "Content-Type" => "application/json" }
  end

  def callback_url
    "#{url}/messages/delivery_status"
  end

  def url
    # For development using ngrok only
    return "#{'https://'}#{ENV['DISPATCH_NGROK_ENDPOINT']}" if ENV['DISPATCH_NGROK_ENDPOINT']

    Rails.application.credentials.root_url
  end
end
