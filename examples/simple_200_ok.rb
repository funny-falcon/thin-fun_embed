# :stopdoc:
require 'thin/fun_embed.rb'

class Simple200ok < Thin::FunEmbed
  def handle_http_request(env)
    if false && rand(2) == 1
      send_200_ok('{"hello":"world"}', 'application/javascript')
    else
      send_200_ok('hello world')
    end
  end
end

EM.run do
  EM.start_server '0.0.0.0', 8080, Simple200ok
end
