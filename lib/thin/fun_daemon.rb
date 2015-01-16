require_relative 'fun_embed'

module Thin
  module FunDaemon
    def self.add_conn(conn)
      @conns ||= {}
      @conns[conn] = true
    end

    def self.del_conn(conn)
      @conns.delete(conn)
      if @trap_called && @conns.empty?
        EM.next_tick{ EM.stop }
      end
    end

    def self.servers
      @servers ||= {}
    end

    def self.trap
      return if @trap_set
      @trap_set = true
      @prev_traps = {}
      [:INT, :TERM, :QUIT].each do |name|
        @prev_traps[name] = ::Signal.trap(name){|sig| trap_call(name, sig) }
      end
    end

    def self.trap_call(name, sig)
      @trap_called = true
      Thread.new do
        EM.schedule do
          servers.each do |serv, _|
            EM.stop_tcp_server serv
          end
          if @conns && !@conns.empty?
            @conns.each do |conn, _|
              conn.force_close!
            end
          else
            EM.next_tick{ EM.stop }
          end
        end
      end
      @prev_traps.each do |nm, prev|
        if nm == name && prev.respond_to?(:call)
          prev.call(sig)
          next
        end
        ::Signal.trap(nm, prev)
      end
    end

    def self.run_class(host, port, klass, *args, &block)
      EM.schedule do
        serv = EM.start_server host, port, klass, *args do |conn|
          yield conn
          conn.unbind_callback = method(:del_conn)
          add_conn conn
        end
        servers[serv] = true
      end
    end

    def self.run_rack(host, port, app = nil, &blk)
      app ||= blk
      run_class host, port, FunRackLike do |conn|
        conn.app = app
      end
    end
  end
end
