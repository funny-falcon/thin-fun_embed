# :stopdoc:
require 'thin/fun_daemon.rb'

app = lambda{|env|
  con = env['async.fun_embed']
  if env['PATH_INFO'] =~ %r{async\/(\d+)}
    EM.add_timer($1.to_f / 1000) do
      con.send_rack_response 200, {'Content-Length'=>6}, ['hello', "\n"]
    end
    con.class::AsyncResponse
  else
    [200, {'Content-Length'=>6}, ['hello', "\n"]]
  end
}

host, port = '0.0.0.0', 8080

Thin::FunDaemon.trap
Thin::FunDaemon.run_rack host, port, app
EM.run
