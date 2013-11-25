require 'io/wait'

class ClientReader
  BUFFER_LIMIT = 1024
  READ_TERMINATOR = /^\s*$/

  attr_accessor :client_socket, :accumulator

  def initialize(client_socket)
    @client_socket = client_socket
    @accumulator   = ''
  end

  #  1. Буфер переполнен
  #  2. Что, если дисконнет?
  #  3. Встретили терминальный символ
  #  4. Может ли быть IO::WaitReadable?
  #  5. retry если клиент тут же готов снова писать
  def read
    @accumulator << @client_socket.read_nonblock(bytes_to_read)
  rescue IO::WaitReadable
    # client is not ready to read as much as promissed?
  rescue Errno::EPIPE
    # client closed connection
  end

  def bytes_to_read
    vacant = [BUFFER_LIMIT - @accumulator.size, 0].max

    [@client_socket.nread, vacant].min
  end

  def terminated?
    @accumulator =~ READ_TERMINATOR
  end

  def buffer_overlimited?
    @accumulator.size >= BUFFER_LIMIT
  end

  def done?
    terminated? || buffer_overlimited?
  end

  # может вернуть nil
  def result
    @accumulator
  end
end