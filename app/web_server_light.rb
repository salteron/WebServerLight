# -*- encoding : utf-8 -*-
require 'socket'
require 'thread'
require 'worker'
require 'config'


# Public: класс для создания экземпляров веб-сервера.
# WebServerLight = легковесный многопоточный веб-сервер.
#
# params - Hash параметров работы веб-сервера:
#          :public_path - строка, полный путь в системе, откуда будут раздаваться
#                       файлы (необязательный) (default: project_dir/public)
#          :port - номер порта, на который сервер принимает соединение
#                  (необязательный) (default: DEFAULT_PORT)
#          :timeout - таймаут (в секундах) для отключения медленных клиентов
#                     (необязательный) (default: DEFAULT_TIMEOUT)
#
# Examples
#
#   server = WebServerLight.new(port: 5000, public_path: ~/public)
#   server.run
class WebServerLight

  def initialize
    @server = TCPServer.open(AppData.port)

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

    AppData.num_of_workers.times do |i|
      threads << Thread.new(i) do |idx|
        Worker.new(@server, idx).work
      end
    end

    threads
  end
end
