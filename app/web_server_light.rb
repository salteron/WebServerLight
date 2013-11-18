require 'worker.rb'
require 'socket'

module WebServerLight

  NUM_OF_WORKERS = 5

  class << self
    attr_accessor :client_queue, :base_path
  end

  module_function

  def run(base_path)
    server         = init_server base_path
    @client_queue  = Queue.new
    worker_threads = init_workers

    loop do
      client = server.accept

      client_queue << client
    end

    worker_threads.each(&:join)
  ensure
    server.close if server
  end

  def init_server base_path
    @base_path = base_path
    trap(:INT) { exit }
    TCPServer.open(3000)
  end

  def init_workers
    Thread.abort_on_exception = true

    threads = []

    NUM_OF_WORKERS.times do |i|
      threads << Thread.new(i) do|idx|
        settings = { base_path: @base_path }
        Worker.new(settings).work idx
      end
    end

    threads
  end
end
