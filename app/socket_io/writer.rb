# -*- encoding : utf-8 -*-

module WebServerLight
  module SocketIO
    # Writes portions of given ios to client socket
    #
    # client_socket  -  socket to non-block write to;
    # ios            -  set of io objects to write from.
    class Writer
      BYTES_TO_SEND_AT_ONCE = 1024

      attr_reader :client_socket, :last_activity

      def initialize(client_socket, ios)
        @client_socket     =  client_socket
        @ios               =  ios

        @ios_sent          = 0
        @bytes_sent        = 0

        @client_socket.sync = true

        update_activity
      end

      def write
        ready = true                      # изначально клиент готов (т.к. select)
        while ready && !enough?           # клиент готов и мы не все отдали
          buffer = read_portion_from_io   # читаем из io кусок predef размера

          sub_bytes_sent = @client_socket.write_nonblock(buffer)
          @bytes_sent +=  sub_bytes_sent

          ready = (sub_bytes_sent == buffer.length) # клиент захавал весь буфер?
                                                   # если да, то наверное готов еще
          switch_to_next_io if current_io_done?   # след файл, если этот закончился

          update_activity
        end
      rescue IO::WaitWritable  # If we can't write even a byte.
        # Should never happen cuz socket is supposed to be writable.
      rescue Errno::EPIPE, Errno::ECONNRESET
        # client closed connection while reading
      end

      def enough?
        success? || @client_socket.closed?
      end

      def close
        close_connections
        close_ios
      end

      def close_connections
        # I/O streams are automatically closed when they are claimed by the garbage
        # collector.
        @client_socket.close unless @client_socket.closed?
      end

      def close_ios
        @ios.each { |io| io.close unless io.closed? }
      end

      def success?
        @ios_sent == @ios.length
      end

      private

      def update_activity
        @last_activity = Time.now
      end


      def current_io
        @ios[@ios_sent]
      end

      def current_io_done?
        @bytes_sent == current_io.size
      end

      def switch_to_next_io
        current_io.close

        @bytes_sent = 0
        @ios_sent  += 1
      end

      # move to offset. then read portion
      def read_portion_from_io
        current_io.seek(@bytes_sent, IO::SEEK_SET)
        current_io.read(BYTES_TO_SEND_AT_ONCE)
      end
    end
  end
end
