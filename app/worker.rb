# -*- encoding : utf-8 -*-
require 'colorize'
require 'app/request'
require 'app/tools/http_response_generator'

module WebServerLight
  # Internal: принимает клиентские соединения и осуществляет их обработку.
  #
  # Клиентское соединение оборачивается в объект типа Request, предназначенный
  # для чтения и формирования клиентского запроса. Когда запрос сформирован,
  # клиентское соединение оборачивается в объект типа Response, реализующий
  # методы передачи запрошенного клиентом ресурса.
  #
  # Формирует и управляет двумя очередями: requests (очередь пишущих соединений)
  # и responses (очередь читающих соединений).
  #
  # Отвергает новые соединения, если количество тех, что находятся в обработке,
  # достигло максимального допустимого значения (параметр max_connections).
  #
  # Периодически осуществляет поиск 'протухших' клиентских соединений и
  # избавляется от них (параметры request_max_service, response_max_idle).
  #
  # server          - сокет, принимающий клиентские соединения;
  # idx             - число-идентификатор воркера;
  # stats_collector - экземпляр StatsCollector, разделяемый всеми воркерами.
  class Worker
    attr_reader :idx, :requests, :responses

    def initialize(server, idx, stats_collector)
      @server    = server
      @idx       = idx

      @requests  = []
      @responses = []

      @stats_collector = stats_collector
    end

    def work
      loop do
        r_sockets = [@server].concat @requests.map(&:client_socket)
        w_sockets = @responses.map(&:client_socket)

        ready     = IO.select(r_sockets, w_sockets) # Wait for sockets to be ready

        get_rid_of_stale  # select мог продлиться долго - проверяем очереди
                          # @requests & @responses на наличие протухших
                          # клиентов

        readable = ready[0].select { |s| @requests.map(&:client_socket).include?(s) || s == @server }
        writable = ready[1].select { |s| @responses.map(&:client_socket).include?(s) }

        readable.each do |socket|
          if socket == @server
            begin
              client_socket = @server.accept_nonblock
              push_request(Request.new(client_socket))
            rescue IO::WaitReadable, Errno::EINTR
              # Другой воркер принял это входящее соединение во время
              # переключения контекста.
            end
          else
            request = @requests.select { |r| r.client_socket == socket }.first
            handle_request request
          end
        end

        writable.each do |socket|
          response = @responses.select { |r| r.client_socket == socket }.first
          handle_response response
        end
      end
    end

    private

    def push_request(request)
      if conn_limit_reached?
        log "rejected new #{request.client_socket}", 'red'
        request.close
      else
        @requests << request
        log "accepted new #{request.client_socket}"
      end
    end

    def conn_limit_reached?
      (@requests.size + @responses.size) == Config::AppData.max_connections
    end

    def handle_request(request)
      request.read

      if request.read?
        @requests.delete(request)

        if request.valid?
          log "uri resolved: #{request.uri.inspect} (#{request.client_socket})",
              'green'

          response = Tools::HTTPResponseGenerator.new.generate_from_uri(
            request.uri,
            request.client_socket
          )

          @responses << response
          log "responding with status: #{response.status.code} and file: #{response.body}"
        else
          log "closing invalid #{request.client_socket}", 'red'
          request.close
        end
      end
    end

    def handle_response(response)
      response.write
      return unless response.written?

      end_up_with_client(response)
    end

    # Удалить reponse из очереди @responses, освободить более неиспользуемые
    # ресурсы (io объекты, данные которых были переданы клиенту), а также
    # закрыть связанное с response клиентское соединение, обновить счетчик
    # обслуживаемых клиентов и собрать статистику в случае, если файл
    # успешно доставлен клиенту.
    def end_up_with_client(client)
      if client.is_a?(Response)
        @responses.delete(client)
      else
        @requests.delete(client)
      end

      client.close

      collect_stats(client) if(client.is_a?(Response))
    end

    def collect_stats(response)
      return unless response.success? && response.status.is_a?(HTTPStatus::HTTPStatus200)

      @stats_collector.collect(response.body)
    end

    def get_rid_of_stale
      before_count = @requests.size + @responses.size

      @requests.select { |r| r.stale? }.each { |r| end_up_with_client(r) }
      @responses.select { |r| r.stale? }.each { |r| end_up_with_client(r) }

      stales_count = before_count - @requests.size - @responses.size

      unless stales_count.zero?
        log("got rid of #{stales_count} stale(s)", 'yellow')
      end
    end

    def log(message, color = nil)
      message = message.to_s.strip.size != 0 ? message : 'unknown error!'
      message[0].downcase!

      log_msg = "Worker##{@idx}: #{message}"
      log_msg = log_msg.send(color) if color

      puts log_msg
    end
  end
end
