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
    worker_threads = init_workers

    loop do
      client = @server.accept

      client_queue << client
    end

    worker_threads.each(&:join)
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
