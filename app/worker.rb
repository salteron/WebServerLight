# -*- encoding : utf-8 -*-
require 'http_request_handler.rb'
require 'http_response_generator.rb'
require 'http_response_sender.rb'

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

  attr_reader :client_queue, :settings, :idx

  def initialize(client_queue, settings, idx)
    @client_queue    = client_queue
    @settings        = settings
    @idx             = idx
  end

  def work
    loop do
      begin
        client = @client_queue.pop

        request  = generate_request  client
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
    end
  end

  private

  def generate_request(client)
    request_handler = HTTPRequestHandler.new
    request = request_handler.handle(client, @settings)

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
