# -*- encoding : utf-8 -*-
require 'timeout'

class HTTPRequestHandler
  HTTP_REQUEST_LINE_REGEXP = %r{
      ^GET            # http method
      \s+             # whitespaces
      \/(?<uri>\S+)   # uri
    }xi

  attr_accessor :timeout

  def initialize(timeout)
    @timeout = timeout
  end

  def handle(client)
    lines = read client
    uri   = parse lines

    Worker::Request.new(client, uri)
  end

  def read(client)
    lines = []

    Timeout.timeout(@timeout) do
      while (line = client.gets) && line !~ /^\s*$/
        lines << line.chomp
      end
    end

    lines
  rescue Timeout::Error
    raise 'slow client rejected'
  end

  def parse(lines)
    request_line = lines[0]

    match    = HTTP_REQUEST_LINE_REGEXP.match(request_line)
    match ? match[:uri] : 'index.html'
  end
end
