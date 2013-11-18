# -*- encoding : utf-8 -*-
require 'http_request_handler.rb'
require 'resource_senders.rb'

# Internal: осуществляет обработку клиентских запросов в отдельном потоке.
# Воркер в цикле извлекает клиентские сокеты из очереди поступающих соединений,
# контролирует парсинг запросов и генерацию ответов. Несколько воркеров может
# работать конкурентно при условии, что очередь клиентских запросов
# потокобезопасная, например, Thread::Queue.
#
# client_queue - указатель на очередь клиентских запросов, ожидающих обработки
# settings     - hash параметров работы worker'а:
#                :timeout - таймаут (секунды) ожидания данных запроса клиента
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
  Request = Struct.new(:client, :resource, :file_path)

  attr_reader :client_queue, :settings, :idx
  attr_reader :request_handler, :resource_sender

  def initialize(client_queue, settings, idx)
    @client_queue    = client_queue
    @settings        = settings
    @idx             = idx

    @request_handler = HTTPRequestHandler.new
    @resource_sender = HTTPResourceSender.new
  end

  def work
    loop do
      begin
        client = @client_queue.pop

        request = form_request client
        @resource_sender.send_resource request
      rescue Errno::EPIPE
        log 'client closed connection'
      rescue => e
        log e.message
      ensure
        client.close
      end
    end
  end

  private

  def form_request(client)
    request           = @request_handler.handle(client, @settings[:timeout])
    request.file_path = resolve_resource_into_path request.resource

    log 'accepted request for file' \
     " #{request.resource} (#{request.file_path})"

    request
  end

  def resolve_resource_into_path(resource)
    base_path = @settings[:base_path]
    path      = File.expand_path File.join(base_path, resource)

    if path.index(base_path) == 0 && File.file?(path) && File.exists?(path)
      path
    else
      File.join(base_path, 'index.html')
    end
  end

  def log(message)
    message[0].downcase!

    puts "Worker##{@idx}: #{message}"
  end
end
