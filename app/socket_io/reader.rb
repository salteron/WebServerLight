# -*- encoding : utf-8 -*-

require 'io/wait'

module WebServerLight
  module SocketIO
    # Реализует неблокирующие чтение из клиентского сокета.
    #
    # Содержит логику останова чтения по: закрытию соединения, переполнению буфера,
    # достижения терминального символа.
    class Reader
      attr_reader :client_socket, :input

      def initialize(client_socket, input_limit, input_terminator)
        @client_socket     = client_socket
        @input_limit       = input_limit
        @input_terminator  = input_terminator
        @input             = ''
        @connection_closed = false
      end

      # Читает из сокета при условии, что он готов.
      # Читает ровно столько, сколько сокет готов передать.
      def read
        if !enough? || client_socket.ready?
          @input << client_socket.read_nonblock(bytes_to_read)
        end
      rescue IO::WaitReadable
        # client is not ready to write as much as promissed? Unlikely
      rescue Errno::EPIPE
        @connection_closed = true
      end

      def enough?
        success? || buffer_overlimited? || @connection_closed
      end

      def close_connection
        # I/O streams are automatically closed when they are claimed by the garbage
        # collector.
        unless @connection_closed
          @client_socket.close
          @connection_closed = true
        end
      end

      private

      def success?
        input =~ @input_terminator
      end

      def buffer_overlimited?
        input.size >= @input_limit
      end

      def bytes_to_read
        vacant = [@input_limit - input.size, 0].max

        [client_socket.nread, vacant].min
      end
    end
  end
end
