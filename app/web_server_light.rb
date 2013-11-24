# -*- encoding : utf-8 -*-

require 'worker.rb'
require 'socket'
require 'thread'

# Public: класс для создания экземпляров веб-сервера.
# WebServerLight = легковесный многопоточный веб-сервер.
#
# params - Hash параметров работы веб-сервера:
#          :base_path - строка, полный путь в системе, откуда будут раздаваться
#                       файлы (необязательный) (default: project_dir/public)
#          :port - номер порта, на который сервер принимает соединение
#                  (необязательный) (default: DEFAULT_PORT)
#          :timeout - таймаут (в секундах) для отключения медленных клиентов
#                     (необязательный) (default: DEFAULT_TIMEOUT)
#
# Examples
#
#   server = WebServerLight.new(port: 5000, base_path: ~/public)
#   server.run
class WebServerLight
  NUM_OF_WORKERS    = 5
  DEFAULT_TIMEOUT   = 5
  DEFAULT_PORT      = 3000

  attr_reader   :server, :port, :settings

  def initialize(params)
    @settings     = {
      base_path: define_base_path(params[:base_path]),
      timeout:   params.fetch(:timeout, DEFAULT_TIMEOUT),
      port:      params.fetch(:port, DEFAULT_PORT)
    }

    @server       = TCPServer.open(@settings[:port])

    trap(:INT) { exit }
  end

  def run
    worker_threads = run_workers

    worker_threads.each(&:join)
  ensure
    @server.close if @server
  end

  private

  def run_workers
    Thread.abort_on_exception = true

    threads = []

    NUM_OF_WORKERS.times do |i|
      threads << Thread.new(i) do |idx|
        Worker.new(@server, @settings, idx).work
      end
    end

    threads
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
