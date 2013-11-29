require 'stringio'
require 'socket_writer'

class Response
  def initialize(client_socket, head, body)
    ios = [StringIO.new(head), File.open(body)]

    @socket_writer = SocketWriter.new(
      client_socket,
      ios
    )
  end

  def client_socket
    @socket_writer.client_socket
  end

  def write
    @socket_writer.write
  end

  def written?
    @socket_writer.enough?
  end

  def success?
    @socket_writer.success?
  end

  def close
    @socket_writer.close
  end
end
