#!/usr/bin/env ruby

require 'json'

begin
  response = `curl -sb -H "Accept: application/json" http://localhost:4040/api/tunnels`
  data = JSON.parse(response)
  public_url = data['tunnels'].first['public_url']
  host = public_url.split("://").last
  puts "Run the following command to set you DISPATCH_NGROK_ENDPOINT env var"
  puts "export DISPATCH_NGROK_ENDPOINT=#{host}"
rescue => e
  puts e.class
  info_message =
<<HEREDOC
################################################################################
Unable to print friendly export ngrok env var command. Make sure ngrok is
started with `ngrok http 3000`. If that doesn't solve the problem, you might
have more than one ngrok tunnels configured. Please visit
http://localhost:4040/api/tunnels, grab the correct public url and set
DISPATCH_NGROK_ENDPOINT env var to the correct value.
################################################################################
HEREDOC
  puts info_message
end
