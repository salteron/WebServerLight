require 'worker.rb'
require 'socket'

module WebServerLight
  Thread.abort_on_exception = true

  def self.run(base_path)
    server = TCPServer.open(3000)
    trap(:INT) { exit }
    threads = []

    5.times do |i|
      threads << Thread.new(server, i + 1) do |s, idx|
        Worker.new(base_path: base_path).work s, idx
      end
    end

  threads.each(&:join)
  ensure
    server.close
  end
end
