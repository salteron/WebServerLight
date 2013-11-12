require 'worker.rb'
require 'socket'

module WebServerLight

  Thread.abort_on_exception = true

  def self.run base_path
    server = TCPServer.open(3000)
    trap(:INT) { exit }
    threads = []

    5.times do
      threads << Thread.new(server, threads.count) do |s, c|
        Worker.new(base_path: base_path).work s, c
      end
    end

  threads.each &:join
  ensure
    server.close
  end
end