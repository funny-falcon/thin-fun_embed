module Thin # :nodoc:
  class FunEmbed
    # Usefull constants for analysing Rack environmentc
    module Constants
      PATH_INFO = 'PATH_INFO'.freeze
      REQUEST_METHOD = 'REQUEST_METHOD'.freeze
      SCRIPT_NAME = 'SCRIPT_NAME'.freeze
      QUERY_STRING = 'QUERY_STRING'.freeze
      SERVER_NAME = 'SERVER_NAME'.freeze
      SERVER_PORT = 'SERVER_PORT'.freeze

      GET = 'GET'.freeze
      POST = 'POST'.freeze
      DELETE = 'DELETE'.freeze
      PUT = 'PUT'.freeze
    end
  end
end
