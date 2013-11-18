# -*- encoding : utf-8 -*-
# TODO: send_file

# Internal: набор методов формирования HTTP ответа, содержащего запрошенный
# клиентом файл.
#
# Examples:
#
#   request # => struct, that holds client (socket) info and requested file path
#   r_sender = HTTPResourceSender.new
#   r_sender.send_resource request
class HTTPResourceSender
  def send_resource(request)
    request.client.puts form_headers(request)

    File.open(request.file_path, 'r') do |src|
      request.client.write src.read(256) until src.eof?
    end
  end

  private

  def form_headers(request)
    headers = [
      'HTTP/1.1 200 OK',
      "Date: #{ Time.now }",
      'Server: WebServerLight',
      "Content-Type: #{define_content_type request.file_path}",
      'Cache-Control: no-cache'
    ]

    # base_name = File.basename request.file_path
    # unless base_name == 'index.html'
    # headers.push "content-disposition: attachment; filename=\"#{base_name}\""
    # headers.push "content-length: #{File.size(request.file_path)}"
    # end

    headers.last << "\r\n\r\n"
    headers.join("\r\n")
  end

  def define_content_type(path)
    ext = File.extname(path)
    return 'text/html'  if ext == '.html' || ext == '.htm'
    return 'text/plain' if ext == '.txt'
    return 'text/css'   if ext == '.css'
    return 'image/jpeg' if ext == '.jpeg' || ext == '.jpg'
    return 'image/gif'  if ext == '.gif'
    return 'image/bmp'  if ext == '.bmp'
    return 'image/x-icon' if ext == '.ico'
    return 'text/plain' if ext == '.rb'
    return 'text/xml'   if ext == '.xml'
    return 'text/xml'   if ext == '.xsl'

    'text/html'
  end
end
