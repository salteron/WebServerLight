# -*- encoding : utf-8 -*-
require 'http_request_parser.rb'
require 'http_response_generator.rb'
require 'http_response_sender.rb'
require 'client_reader.rb'

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
  Request =  Struct.new(:client, :resource, :base_path)
  Response = Struct.new(:client, :status, :headers, :file_path)

  attr_reader :server, :settings, :idx
  attr_accessor :r_sockets, :w_sockets

  def initialize(server, settings, idx)
    @server   = server
    @settings = settings
    @idx      = idx

    @r_sockets = [@server]
    @w_sockets = []

    @client_readers = []
    @client_writers = []
  end

  def work
    loop do
      r_sockets = [@server].concat @client_readers.map(&:client_socket)
      w_sockets = @client_writers.map(&:client_socket)

      ready    = IO.select(r_sockets, w_sockets)  # Wait for sockets to be ready
      readable = ready[0]                         # These sockets are readable
      writable = ready[1]                         # These sockets are writable

      readable.each do |socket|
        if socket == @server        # If the server socket is ready
          client = @server.accept   # Accept a new client
          @client_readers << ClientReader.new(client)
        else                        # Otherwise, a client is ready
          cr = @client_readers.select{ |cr| cr.client_socket == socket }.first
          read_from_client cr
        end
      end
    end
  end

  def read_from_client(client_reader)
    client_reader.read

    if client_reader.done?
      if client_reader.terminated?
        @client_readers.delete(client_reader)
        serve_client(client_reader.client_socket, client_reader.result)
      else
        # давай досвидания (буфер переполнен). удалить из чит очереди
        @client_readers.delete(client_reader)
        client_reader.client_socket.close
      end
    end
  rescue Errno::EPIPE
    log 'client closed connection'
  end

  def serve_client(client, input)
    request  = generate_request  client, input
    response = generate_response request

    HTTPResponseSender.new.send_response response
  rescue Errno::EPIPE
    log 'client closed connection'
  rescue => e
    log e.message
    # send_500 client if client
  ensure
    client.close if client
  end

  private

  def generate_request(client, input)
    request_handler = HTTPRequestParser.new
    request = request_handler.parse_uri(client, input, @settings[:base_path])

    log "accepted request for resource #{request.resource}"

    request
  end

  def generate_response(request)
    response_generator = HTTPResponseGenerator.new
    response = response_generator.generate(request)

    log "formed response: #{response.status}: #{response.file_path}"

    response
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
