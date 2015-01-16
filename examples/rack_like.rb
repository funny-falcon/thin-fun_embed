# :stopdoc:
require 'thin/fun_daemon.rb'

app = proc{|env|
  [200, {'Content-Length'=>6}, ['hello', "\n"]]
}

host, port = '0.0.0.0', 8080

Thin::FunDaemon.trap
Thin::FunDaemon.run_rack host, port, app
EM.run
