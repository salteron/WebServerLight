# -*- encoding : utf-8 -*-
require 'timeout'

class HTTPRequestHandler
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
    line  = nil

    Timeout.timeout(@timeout) do
      lines << line.chomp while (line = client.gets) && line !~ /^\s*$/

      lines
    end
  rescue Timeout::Error
    raise 'slow client rejected'
  end

  def parse(lines)
    request_line = lines[0]

    req_line_regexp = %r{
      ^GET            # http method
      \s+             # whitespaces
      \/(?<uri>\S+)   # uri
    }xi

    match    = req_line_regexp.match(request_line)
    match ? match[:uri] : 'index.html'
  end
end
