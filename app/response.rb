# -*- encoding : utf-8 -*-

require 'forwardable'
require 'stringio'
require 'erb'
require 'app/socket_io/writer'
require 'app/tools/stats_collector'
require 'app/exceptions/http_500_exception'

module WebServerLight
  # Объект, представляющих состояние ответа на клиентский запрос.
  #
  # Ответ может быть записываемым или записанным.
  #   Записываемый ответ может быть 'протухшим' или нет.
  #   Записанный ответ - либо все данные переданы клиенту, либо клиент разорвал
  #     соединение.
  #
  # Делегирует запись в клиентский сокет связанному с собой объекту типа
  # SocketWriter.
  class Response
    extend Forwardable

    attr_reader :body, :status

    def_delegators :@socket_writer, :write, :client_socket, :success?
    def_delegators :@socket_writer, :close_ios, :close
    def_delegator  :@socket_writer, :enough?, :written?

    def initialize(client_socket, status, head, body)
      ios     = [StringIO.new(head), body_to_io(body)]
      @body   = body
      @status = status

      @socket_writer = SocketIO::Writer.new(
        client_socket,
        ios
      )
    end

    # Ответ считается 'протухшим', если с момента последнего чтения клиента
    # прошло больше response_max_idle секунд.
    def stale?
      (Time.now - @socket_writer.last_activity) > Config::AppData.response_max_idle
    end

    private

    def body_to_io(file_path)
      if File.extname(file_path) == '.erb'
        erb_to_io(file_path)
      else
        File.open(file_path)
      end
    end

    def erb_to_io(file_path)
      StringIO.new ERB.new(File.read(file_path)).result
    rescue
      raise Exceptions::HTTP500Exception
    end
  end
end
