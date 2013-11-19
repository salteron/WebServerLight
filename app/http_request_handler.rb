# -*- encoding : utf-8 -*-
require 'timeout'

# Internal: набор методов для чтения из клиентского сокета и излвечения из
# текста запроса идентификатора (uri) запрашиваемого файла (ресурса).
# Медленные клиенты отсоединеняются по таймауту.
class HTTPRequestHandler
  HTTP_REQUEST_LINE_REGEXP = %r{
      ^GET            # http method
      \s+             # whitespaces
      \/(?<uri>\S+)   # uri
    }xi

  def handle(client, settings)
    lines = read client, settings[:timeout]
    uri   = extract_uri lines

    Worker::Request.new(client, uri, settings[:base_path])
  end

  private

  def read(client, timeout)
    lines = []

    Timeout.timeout(timeout) do
      while (line = client.gets) && line !~ /^\s*$/
        lines << line.chomp
      end
    end

    lines
  rescue Timeout::Error
    raise 'slow client rejected'
  end

  def extract_uri(lines)
    request_line = lines[0]

    match = HTTP_REQUEST_LINE_REGEXP.match(request_line)
    match ? match[:uri] : 'index.html'
  end
end
