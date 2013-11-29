# -*- encoding : utf-8 -*-
require 'http_response_generator'
require 'request'

# Internal: осуществляет обработку клиентских запросов в отдельном потоке.
# Воркер в цикле извлекает клиентские сокеты из очереди поступающих соединений,
# контролирует парсинг запросов и генерацию ответов. Несколько воркеров может
# работать конкурентно при условии, что очередь клиентских запросов
# потокобезопасная, например, Thread::Queue.
#
# client_queue - указатель на очередь клиентских запросов, ожидающих обработки
# settings     - hash параметров работы worker'а:
#                :timeout - таймаут (секунды) ожидания данных запроса клиента
#                :base_path - полный путь к папке, из которой раздаются файлы
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

  def initialize(server, settings, idx)
    @server   = server
    @settings = settings
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
          @requests << Request.new(client_socket)
          log "accepted new connection"
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

  def handle_request(request)
    request.read
    log 'reading from request'
    if request.read?
      @requests.delete(request)

      if request.valid?
        response = HTTPResponseGenerator.new.generate_from_uri(
          request.uri,
          request.client_socket
        )

        @responses << response
        log "request for #{request.uri.inspect} generated"
      else
        log "closing invalid request"
        request.close
      end
    end
  end

  def handle_response(response)
    response.write
    log "writing response (#{response})"
    return unless response.written?

    log "response closed"
    @responses.delete(response)
    response.close
  end

  def log(message)
    message = (message.to_s.strip.size != 0) ? message : 'unknown error!'
    message[0].downcase!

    puts "Worker##{@idx}: #{message}"
  end

  def send_500(client)
    r_500 = HTTPResponseGenerator.new.generate_500(client)
    HTTPResponseSender.new.send_response(r_500)
  end
end
