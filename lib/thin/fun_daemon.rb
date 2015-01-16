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
      ::Signal.trap(:INT){ trap_call }
      ::Signal.trap(:TERM){ trap_call }
      ::Signal.trap(:QUIT){ trap_call }
    end

    def self.trap_call
      @trap_called = true
      Thread.new do
        EM.schedule do
          servers.each do |serv, _|
            EM.stop_tcp_server serv
          end
          if @conns && !@conns.empty?
            @conns.each do |conn, _|
              conn.close_connection_after_writing
            end
          else
            EM.next_tick{ EM.stop }
          end
        end
      end
      ::Signal.trap(:INT, 'DEFAULT')
      ::Signal.trap(:TERM, 'DEFAULT')
      ::Signal.trap(:QUIT, 'DEFAULT')
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
