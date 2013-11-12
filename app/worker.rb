require 'request_handlers.rb'
require 'resource_senders.rb'

class Worker
  attr_reader :request_handler, :resource_sender, :settings

  def initialize(settings)
    @settings        = settings

    @request_handler = HTTPRequestHandler.new
    @resource_sender = HTTPResourceSender.new
  end

  def work server, idx
    loop do
      begin
        client = server.accept
        puts "#{idx} accepted connection!"

        request = @request_handler.parse client
        request.file_path = resolve_resource_into_path request.resource

        @resource_sender.send_resource request
      rescue => e
        puts "#{idx} error: " + e.message
      ensure
        client.close
      end
    end
  end

  def resolve_resource_into_path resource
    base_path = @settings[:base_path]
    path      = File.expand_path File.join base_path, resource

    (path.match(/#{base_path}/) and not File.directory?(path) and File.exists?(path)) ?
        path : File.join(base_path, '/index.html')
  end
end