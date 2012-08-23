require "eventmachine"
require "thin_parser"
require "thin/request"
require "thin/statuses"
require "thin/fun_embed/version"
require "thin/fun_embed/constants"

module Thin # :nodoc:
  SERVER = "FunEmbed #{FunEmbed::VERSION}".freeze
  module VERSION # :nodoc:
    RACK = [1,1].freeze
  end

  # minimalistic HTTP server for embedding into EventMachine'd applications
  #
  # Method #handle_http_request accept fully formed Rack environment and should
  # call send http status+headers+body using one of #send_200_ok, #send_status_body,
  # #send_raw_string and #send_rack_response methods or manually. If you send
  # response manually, then you should call #consider_keep_alive method with your wish:
  # whether you want to try keep-alive connection or not.
  #
  #   require 'thin/fun_embed.rb'
  #   
  #   class Simple200ok < Thin::FunEmbed
  #     def handle_http_request(env)
  #       if rand(2) == 1
  #         send_200_ok('{"hello":"world"}', 'application/javascript')
  #       else
  #         send_200_ok('hello world')
  #       end
  #     end
  #   end
  #   
  #   EM.run do
  #     EM.start_server '0.0.0.0', 8080, Simple200ok
  #   end
  # 
  class FunEmbed < EM::Connection
    # :stopdoc:
    include Constants
    FULL_KEEP_ALIVE = "Connection: keep-alive\r\n".freeze
    RN = "\r\n".freeze
    RNRN = "\r\n\r\n".freeze
    NL = "\n".freeze
    CONTENT_LENGTH = "Content-Length".freeze
    CONTENT_LENGTH_DT = "\r\nContent-Length: ".freeze
    CONNECTION = 'Connection'.freeze
    KEEP_ALIVE = 'keep-alive'.freeze
    CLOSE = 'close'.freeze
    TEXT_PLAIN = 'text/plain'.freeze
    HTTP_STATUS_CODES = Thin::HTTP_STATUS_CODES
    # :startdoc:

    # callback, which called from +#unbind+.
    # Could be used for monitoring connections.
    attr_accessor :unbind_callback

    # signals if client may accept keep-alive connection
    attr :keep_alive

    def post_init
      @keep_alive = nil
      @parser = Thin::Request.new
    end

    def receive_data(data)
      if @parser.parse(data)
        @keep_alive = @parser.persistent?
        handle_http_request(@parser.env)
      end
    end

    # main method for override
    # you ought to put your application logic here
    def handle_http_request(env)
      send_200_ok "you should override #handle_http_request"
    end

    # send simple '200 OK' response with a body
    def send_200_ok(body = '', type = TEXT_PLAIN, try_keep_alive = true)
      send_data("HTTP/1.1 200 OK\r\nContent-Type: #{type}\r\n"\
                "Content-Length: #{body.bytesize}\r\n"\
                "#{keep_alive ? FULL_KEEP_ALIVE : nil}\r\n")
      send_data(body)
      consider_keep_alive(try_keep_alive)
    end

    # send simple response with status, body and type
    def send_status_body(status, body = '', type = TEXT_PLAIN, try_keep_alive = true)
      status = status.to_i
      if status < 200 || status == 204 || status == 304
        send_data("HTTP/1.1 #{status} #{HTTP_STATUS_CODES[status]}\r\n"\
                "#{keep_alive ? FULL_KEEP_ALIVE : nil}\r\n")
      else
        send_data("HTTP/1.1 #{status} #{HTTP_STATUS_CODES[status]}\r\n"\
                "Content-Type: #{type}\r\n"\
                "Content-Length: #{body.bytesize}\r\n"\
                "#{keep_alive ? FULL_KEEP_ALIVE : nil}\r\n")
        send_data(body)
      end
      consider_keep_alive(try_keep_alive)
    end

    # send fully formatted HTTP response
    def send_raw_string(string, try_keep_alive = true)
      send_data(string)
      try_keep_alive &&= @keep_alive &&
        (cl = string.index(CONTENT_LENGTH_DT)) &&
        (kai = string.index(FULL_KEEP_ALIVE)) && 
        kai < (rn = string.index(RNRN)) &&
        cl < rn
      consider_keep_alive(try_keep_alive)
    end

    # send Rack like response (status, headers, body)
    #
    # This method tries to implement as much of Rack as it progmatically needed, but not more.
    # Test it before use
    def send_rack_response(status, headers, body, try_keep_alive = true)
      status = status.to_i
      out = "HTTP/1.1 #{status} #{HTTP_STATUS_CODES[status]}\r\n"

      if String === headers
        try_keep_alive &&= headers.index(CONTENT_LENGTH_DT) && headers.index(FULL_KEEP_ALIVE)
        out << headers
      else
        content_length = connection = nil
        headers.each do |k, v|
          if k == CONTENT_LENGTH
            content_length = v
          elsif k == CONNECTION
            connection = v
          end
          if String === v
            unless v.index(NL)
              out << "#{k}: #{v}\r\n"
            else
              v.each_line{|l| out << "#{k}: #{l}\r\n"}
            end
          elsif v.respond_to?(:each)
            v.each{|l| out << "#{k}: #{l}\r\n"}
          else
            unless (v=v.to_s).index(NL)
              out << "#{k}: #{v}\r\n"
            else
              v.each_line{|l| out << "#{k}: #{l}\r\n"}
            end
          end
        end

        try_keep_alive &&= @keep_alive && content_length && (!connection || connection == KEEP_ALIVE)
        out << FULL_KEEP_ALIVE  if try_keep_alive && !connection
      end
      out << RN
      send_data out

      if String === body
        send_data(body)
      else
        body.each{|s| send_data(s)}
      end

      consider_keep_alive(try_keep_alive)
    end

    # call this when you fully send response
    def consider_keep_alive(try_keep_alive = true)
      @request.close  rescue nil
      if @keep_alive && try_keep_alive
        post_init
      else
        close_connection_after_writing
      end
    end

    def unbind # :nodoc:
      @unbind_callback && @unbind_callback.call(self)
    end
  end
end
