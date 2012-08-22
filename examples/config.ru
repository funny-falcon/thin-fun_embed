app = proc{|env| [200, {'Content-Length'=>'6'}, ['hello', "\n"]]}
run app
