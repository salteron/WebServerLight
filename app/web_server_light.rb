# -*- encoding : utf-8 -*-
require 'socket'
require 'thread'
require 'config/config'
require 'app/worker'
require 'app/tools/stats_collector'

# WebServerLight = легковесный многопоточный веб-сервер.
#
# Отвечает за создание принимающего клиентские соединения сокета,
# инициализацию Worker'ов и разделяемых ими ресурсов.
#
# config.rb
#  num_of_workers  - количество создаваемых воркеров;
#  port            - порт, на который принимаются соединения;
#  public_path     - путь, по которому находятся ресурсы веб-сервера.
#
# Examples
#
#   server = WebServerLight.new
#   server.run
module WebServerLight
  extend self

  def run
    trap(:INT) { exit }
    @server = TCPServer.open(Config::AppData.port)

    worker_threads = run_workers

    worker_threads.each(&:join)
  ensure
    @server.close if @server
  end

  private

  def run_workers
    Thread.abort_on_exception = true
    stats_collector = Tools::StatsCollector.new

    threads = []

    Config::AppData.num_of_workers.times do |i|
      threads << Thread.new(i) do |idx|
        Worker.new(@server, idx, stats_collector).work
      end
    end

    threads
  end
end
