require 'stringio'

# Writes portions of the given file to client socket
#
# client_socket  -  socket to non-block write to;
# file_path      -  path of the file to write from.
class SocketWriter
  BYTES_TO_SEND_AT_ONCE = 1024

  attr_reader :client_socket

  def initialize(client_socket, ios)
    @client_socket     =  client_socket
    @ios               =  ios

    @ios_sent          = 0
    @bytes_sent        = 0

    @client_socket.sync = true
    @connection_closed  = false
  end

  # пишем, если
  #   не все написали
  #   клиент не закрыл соединение
  # обязательно повторяем, если клиент прочитал буфер полностью
  def write
    ready = true                          # изначально клиент готов
    while ready && !enough?               # клиент готов и мы не все отдали
      buffer = read_portion_from_io       # читаем из io кусок predef размера

      sub_bytes_sent = @client_socket.write_nonblock(buffer)
      @bytes_sent +=  sub_bytes_sent

      ready = (sub_bytes_sent == buffer.length)  # клиент захавал весь буфер?
                                               # если да, то наверное готов еще
      switch_to_next_io if current_io_done?    # след файл, если этот закончился
    end
  rescue IO::WaitWritable
    # If we can't write even a byte.
    # Should never happen cuz socket is supposed to be writable.
  rescue Errno::EPIPE, Errno::ECONNRESET
    @connection_closed = true
  end

  def enough?
    success? || @connection_closed
  end

  def close
    # I/O streams are automatically closed when they are claimed by the garbage
    # collector.
    #unless @connection_closed
      @client_socket.close
      @connection_closed = true
    #end

    @ios.each { |io| io.close unless io.closed? }
  end

  def success?
    @ios_sent == @ios.length
  end

  private

  def current_io
    @ios[@ios_sent]
  end

  def current_io_done?
    done = @bytes_sent == current_io.size
    raise if done && !current_io.eof?  # debugging
    done
  end

  def switch_to_next_io
    current_io.close

    @bytes_sent = 0
    @ios_sent  += 1
  end

  # name. length. offset
  def read_portion_from_io
    current_io.seek(@bytes_sent, IO::SEEK_SET)
    current_io.read(BYTES_TO_SEND_AT_ONCE)
  end
end
