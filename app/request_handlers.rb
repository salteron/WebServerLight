require 'timeout'

class Request
  attr_accessor :client, :resource, :file_path

  def initialize(client, resource)
    @client   = client
    @resource = resource
  end
end

class HTTPRequestHandler

  def parse client

    lines = []
    Timeout.timeout(5) do

      while (line = client.gets) and line !~ /^\s*$/
        lines << line.chomp
      end
    end

    request_line = lines[0]

    resource = request_line =~ /^GET\s+\/(\S+)/i ? $1 : "index.html"

    Request.new client, resource
  end

=begin
  def parse client
    request      = WEBrick::HTTPRequest.new(:Logger => nil)
    # TODO: handle errors # https://github.com/ruby/ruby/blob/trunk/lib/webrick/httprequest.rb#191
    request.parse client

    Request.new client, request.path
  end
=end

end