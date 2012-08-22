# :stopdoc:
require 'thin/fun_embed.rb'

class RackLikeServer < Thin::FunEmbed
  attr_accessor :app
  def handle_http_request(env)
    send_rack_response(*app.call(env))
  end
end

app = proc{|env| [200, {'Content-Length'=>6}, ['hello', "\n"]]}

host, port = '0.0.0.0', 8080
all_conns = {}
trap(:INT) do 
  EM.schedule{ 
    all_conns.each{|conn, _| conn.close_after_writting}
    EM.next_tick{ EM.stop }
  } 
end

EM.run do
  EM.start_server host, port, RackLikeServer do |conn|
    conn.app = app
    all_conns[conn] = true
    conn.unbind_callback = all_conns.method(:delete)
  end
end
