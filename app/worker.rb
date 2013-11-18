# -*- encoding : utf-8 -*-
require 'http_request_handler.rb'
require 'resource_senders.rb'

class Worker
  Request = Struct.new(:client, :resource, :file_path)

  attr_reader :client_queue, :settings, :idx
  attr_reader :request_handler, :resource_sender

  def initialize(client_queue, settings, idx)
    @client_queue    = client_queue
    @settings        = settings
    @idx             = idx

    @request_handler  = HTTPRequestHandler.new(@settings[:timeout])
    @resource_sender = HTTPResourceSender.new
  end

  def work
    loop do
      begin
        client = @client_queue.pop

        request           = @request_handler.handle client
        request.file_path = resolve_resource_into_path request.resource

        puts "#{@idx} accepted connection for file #{request.resource}" \
             " (#{request.file_path})"

        @resource_sender.send_resource request
      rescue => e
        puts "#{@idx} error: " + e.message
      ensure
        client.close
      end
    end
  end

  def resolve_resource_into_path(resource)
    base_path = @settings[:base_path]
    path      = File.expand_path File.join base_path, resource

    if path.index(base_path) == 0 && File.file?(path) && File.exists?(path)
      path
    else
      File.join(base_path, 'index.html')
    end
  end
end
