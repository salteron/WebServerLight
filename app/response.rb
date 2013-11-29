require 'stringio'
require 'socket_writer'
require 'erb'

class Response
  def initialize(client_socket, head, body)
    ios = [StringIO.new(head), body_to_io(body)]

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

  def stale?
    (Time.now - @socket_writer.last_activity) > AppData.response_max_idle
  end

  private

  def body_to_io(file_path)
    if File.extname(file_path) == '.erb'
      StringIO.new ERB.new(File.read(file_path)).result
    else
      File.open(file_path)
    end
  end
end
