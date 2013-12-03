# -*- encoding : utf-8 -*-
require 'request'
require 'http_response_generator'
require 'colorize'

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

      ready    = IO.select(r_sockets, w_sockets) # Wait for sockets to be ready
      readable = ready[0]                        # These sockets are readable
      writable = ready[1]                        # These sockets are writable

      readable.each do |socket|
        if socket == @server
          client_socket = @server.accept
          push_request(Request.new(client_socket))
        else
          request = @requests.select { |r| r.client_socket == socket }.first
          handle_request request
        end
      end

      writable.each do |socket|
        response = @responses.select { |r| r.client_socket == socket }.first
        handle_response response
      end

      get_rid_of_stale
    end
  end

  private

  def push_request(request)
    if conn_limit_reached?
      log "rejected new #{request.client_socket}", 'red'
    else
      @requests << request
      log "accepted new #{request.client_socket}"
    end
  end

  def conn_limit_reached?
    (@requests.size + @responses.size) == AppData.max_connections
  end

  def handle_request(request)
    request.read

    if request.read?
      @requests.delete(request)

      if request.valid?
        log "uri resolved: #{request.uri.inspect} (#{request.client_socket})",
            'green'

        response = HTTPResponseGenerator.new.generate_from_uri(
          request.uri,
          request.client_socket
        )

        @responses << response
      else
        log "closing invalid #{request.client_socket}", 'red'
        request.close
      end
    end
  end

  def handle_response(response)
    response.write
    return unless response.written?

    end_up_with_response(response)
  end

  # Удалить reponse из очереди @responses, освободить более неиспользуемые
  # ресурсы (io объекты, данные которых были переданы клиенту), а также
  # закрыть связанное с response клиентское соединение, если работа с ним
  # завершена.
  def end_up_with_response(response, close_conn = true)
    log "closing #{response.client_socket}"

    @responses.delete(response)
    close_conn ? response.close : response.close_ios

    return unless response.success? && response.status.is_a?(HTTPStatus200)

    @stats_collector.collect(response.body)
  end

  def get_rid_of_stale
    stales_count = 0

    [@requests, @responses].each do |queue|
      stales = queue.select { |r| r.stale? }

      stales.each do |stale|
        stale.close
        queue.delete(stale)
      end

      stales_count += stales.size
    end

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
