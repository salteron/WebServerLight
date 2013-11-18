# -*- encoding : utf-8 -*-
$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))

require 'worker.rb'
require 'socket'

class WebServerLight
  NUM_OF_WORKERS    = 5
  DEFAULT_TIMEOUT   = 5

  attr_accessor :client_queue
  attr_reader   :server, :settings

  def initialize(params)
    @settings     = {
      base_path: define_base_path(params[:base_path]),
      timeout:   params.fetch(:timeout, DEFAULT_TIMEOUT)
    }

    @server       = TCPServer.open(3000)
    @client_queue = Queue.new

    trap(:INT) { exit }
  end

  def init_workers
    Thread.abort_on_exception = true

    threads = []

    NUM_OF_WORKERS.times do |i|
      threads << Thread.new(i) do |idx|
        Worker.new(@client_queue, @settings, idx).work
      end
    end

    threads
  end

  def run
    init_workers
    sockets = [@server]            # An array of sockets we'll monitor

    loop do
      ready   = select(sockets)    # Wait for sockets to be ready
      readable = ready[0]          # These sockets are readable

      readable.each do |socket|
        if socket == @server       # If the server socket is ready
          client = @server.accept  # Accept a new client
          sockets << client        # Add it to the set of sockets
        else                       # Otherwise, a client is ready
          sockets.delete(socket)   # Удаляем из общей очереди соединений
          @client_queue << socket  # Пушим в очередь, просматриваемую воркерами
        end
      end
    end
  ensure
    server.close if server
  end

  def define_base_path(path)
    if path.nil? || File.file?(File.expand_path(path))
      default_base_path
    else
      File.expand_path path
    end
  end

  def default_base_path
    app_dir = File.expand_path(File.dirname(__FILE__))
    File.expand_path("#{app_dir}/../public")
  end
end
