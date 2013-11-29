# -*- encoding : utf-8 -*-
require 'request'
require 'http_response_generator'
require 'colorize'

# Internal: осуществляет обработку клиентских запросов в отдельном потоке.
# Воркер в цикле извлекает клиентские сокеты из очереди поступающих соединений,
# контролирует парсинг запросов и генерацию ответов. Несколько воркеров может
# работать конкурентно при условии, что очередь клиентских запросов
# потокобезопасная, например, Thread::Queue.
#
# client_queue - указатель на очередь клиентских запросов, ожидающих обработки
# settings     - hash параметров работы worker'а:
#                :timeout - таймаут (секунды) ожидания данных запроса клиента
#                :public_path - полный путь к папке, из которой раздаются файлы
# idx          - число-идентификатор воркера
#
# Examples:
#
#  client_queue = Queue.new  # => Thread-safe queue
#  settings     = { timeout: 3 }
#  5.times do |i|
#    Thread.new(idx) { Worker.new(client_queue, settings, idx).work }
#  end
#  # => 5 параллельно работающих воркера.
class Worker
  attr_reader :idx, :requests, :responses

  def initialize(server, idx)
    @server   = server
    @idx      = idx

    @requests  = []
    @responses = []
  end

  def work
    loop do
      r_sockets = [@server].concat @requests.map(&:client_socket)
      w_sockets = @responses.map(&:client_socket)

      ready    = IO.select(r_sockets, w_sockets)  # Wait for sockets to be ready
      readable = ready[0]                         # These sockets are readable
      writable = ready[1]                         # These sockets are writable

      readable.each do |socket|
        if socket == @server
          client_socket = @server.accept
          push_request(Request.new(client_socket))
        else
          r = @requests.select{ |r| r.client_socket == socket }.first
          handle_request r
        end
      end

      writable.each do |socket|
        r = @responses.select{ |r| r.client_socket == socket }.first
        handle_response r
      end
    end
  end

  private

  def push_request(request)
    get_rid_of_stale if conn_limit_reached?

    if conn_limit_reached?  # still
      log "rejected new #{request}", 'red'
    else
      @requests << request
      log "accepted new #{request}", 'green'
    end
  end

  def conn_limit_reached?
    (@requests.size + @responses.size) == AppData.max_connections
  end

  def get_rid_of_stale
    stales_count = 0

    [@requests, @responses].each do |queue|
      before_count = queue.size

      stales = queue.select { |r| r.stale? }
      stales.each do |r|
        r.close
        queue.delete(r)
      end

      stales_count += before_count - queue.size

    end

    unless stales_count.zero?
      log("got rid of #{stales_count} stale(s)", 'yellow')
    end
  end

  def handle_request(request)
    # log "reading from #{request}"
    request.read

    if request.read?
      @requests.delete(request)

      if request.valid?
        response = HTTPResponseGenerator.new.generate_from_uri(
          request.uri,
          request.client_socket
        )

        @responses << response
        log "uri resolved: #{request.uri.inspect} (#{request})", 'green'
      else
        log "closing invalid #{request}", 'red'
        request.close
      end
    end
  end

  def handle_response(response)
    # log "writing #{response}"
    response.write
    return unless response.written?

    log "transferred", 'green'
    @responses.delete(response)
    response.close
  end

  def log(message, color = nil)
    message = (message.to_s.strip.size != 0) ? message : 'unknown error!'
    message[0].downcase!

    log_msg = "Worker##{@idx}: #{message}"
    log_msg = log_msg.send(color) if color

    puts log_msg
  end
end
