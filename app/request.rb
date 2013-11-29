require 'http_input_parser.rb'
require 'socket_reader.rb'

class Request
  INPUT_LIMIT      = 1024
  INPUT_TERMINATOR = /\n\s*\n/

  attr_reader :uri

  def initialize(client_socket)
    @socket_reader = SocketReader.new(
      client_socket,
      INPUT_LIMIT,
      INPUT_TERMINATOR
    )

    @birth_time = Time.now
  end

  def client_socket
    @socket_reader.client_socket
  end

  def read
    @socket_reader.read
  end

  # закончили читать реквест?
  def read?
    @socket_reader.enough?
  end

  # валидный ли реквест?
  def valid?
    parse(@socket_reader.input) if read?

    !uri.nil?
  end

  def close
    @socket_reader.close_connection
  end

  def stale?
    (Time.now - @birth_time) > AppData.request_max_service
  end

  private

  def parse(input)
    @uri = HTTPInputParser.new.parse_uri(input)
  end
end
