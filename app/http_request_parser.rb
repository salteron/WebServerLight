# -*- encoding : utf-8 -*-
require 'timeout'
require 'stringio'

# Internal: набор методов для чтения из клиентского сокета и излвечения из
# текста запроса идентификатора (uri) запрашиваемого файла (ресурса).
# Медленные клиенты отсоединеняются по таймауту.
class HTTPRequestParser
  HTTP_REQUEST_LINE_REGEXP = %r{
      ^GET            # http method
      \s+             # whitespaces
      \/(?<uri>\S+)   # uri
    }xi

    INDEX_PATH = 'index.html'

  def parse_uri(client, input, base_path)
    lines = parse_input input
    uri   = extract_uri lines

    Worker::Request.new(client, uri, base_path)
  end

  private

  def parse_input(input)
    lines = []
    sio = StringIO.new(input)

    while (line = sio.gets)
      lines << line.chomp
    end

    lines
  end

  def extract_uri(lines)
    request_line = lines[0]

    match = HTTP_REQUEST_LINE_REGEXP.match(request_line)
    match ? match[:uri] : INDEX_PATH
  end
end
