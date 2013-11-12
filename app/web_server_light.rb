require 'worker.rb'
require 'socket'

module WebServerLight

  Thread.abort_on_exception = true

  def self.run base_path
    server = TCPServer.open(3000)
    trap(:INT) { exit }

    loop do
      client      = server.accept
      client.sync = true

      w = Worker.new(client, base_path: base_path)

      Thread.new do
        w.work
      end
    end
  end
end