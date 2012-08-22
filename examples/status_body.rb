# :stopdoc:
require 'thin/fun_embed.rb'

class StatusBody < Thin::FunEmbed
  def handle_http_request(env)
    if env[PATH_INFO] =~ /\.js$/
      send_status_body(200, '{"hello":"world"}', 'application/javascript')
    else
      send_status_body(200, 'hello world')
    end
  end
end

EM.run do
  EM.start_server '0.0.0.0', 8080, StatusBody
end
