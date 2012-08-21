require "thin-fun_embed/version"
require "eventmachine"
require "thin_parser"
require "thin/request"
require "thin/statuses"

module Thin
  module FunEmbed
    class Base < EM::Connection
      FULL_KEEP_ALIVE = "Connection: keep-alive\r\n".freeze
      RN = "\r\n".freeze
      CONTENT_LENGTH = "Content-Length".freeze
      CONNECTION = 'Connection'.freeze
      CLOSE = 'close'.freeze
      HTTP_STATUS_CODES = Thin::HTTP_STATUS_CODES

      def post_init
        @parser = Thin::Request.new
      end

      def receive_data(data)
        if @parser.parse(data)
          handle_http_request(@parser.persistent?, @parser.env)
        end
      end

      # main method for override
      # you ought to put your application logic here
      def handle_http_request(keep_alive, env)
        send_200_ok keep_alive, "you should override #handle_http_request"
      end

      def send_200_ok(data, keep_alive)
        send_data("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{data.bytesize}\r\n"\
                  "#{keep_alive ? FULL_KEEP_ALIVE : nil}\r\n")
        send_data(data)
        consider_keep_alive(keep_alive)
      end

      def send_raw_string(keep_alive, string)
        send_data(string)
        consider_keep_alive(keep_alive)
      end

      def send_rack_response(keep_alive, status, headers, body)
        status = status.to_i
        keep_alive = false unless headers[CONTENT_LENGTH]
        keep_alive = false if headers[CONNECTION] == CLOSE
        out = "HTTP/1.1 #{status} #{HTTP_STATUS_CODES[status]}\r\n"
        headers.each do |k, v|
          if String === v
            v.each_line{|l| out << "#{k}: #{l}\r\n"}
          elsif v.respond_to?(:each)
            v.each{|l| out << "#{k}: #{l}\r\n"}
          else
            v.to_s.each_line{|l| out << "#{k}: #{l}\r\n"}
          end
        end
        if keep_alive && !headers[CONNECTION]
          out << FULL_KEEP_ALIVE
        end
        out << RN
        if String === body
          send_data(body)
        else
          body.each{|s| send_data(s)}
        end
        consider_keep_alive(keep_alive)
      end

      def consider_keep_alive(keep_alive)
        if keep_alive
          post_init
        else
          close_connection_after_writing
        end
      end
    end

    class WithManager < Base
      attr_reader :manager
      def post_init
        super
        @manager.connection_established self
      end

      def unbind
        @manager.connection_closed self
      end
    end
  end
end
