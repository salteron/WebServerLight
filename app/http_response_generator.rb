# -*- encoding : utf-8 -*-
# TODO: send_file

# Internal: набор методов формирования HTTP ответа, содержащего запрошенный
# клиентом файл.
#
# Examples:
#
#   request # => struct, that holds client (socket) info and requested resource
#   r_sender = HTTPResponseGenerator.new
#   r_sender.send_response request
class HTTPResponseGenerator

  def generate(request, base_path)
    client    = request.client
    file_path = resolve_resource_into_path base_path, request.resource
    status    = resolve_status_code base_path, file_path
    headers   = form_headers status, file_path
    
    Worker::Response.new(client, status, headers, file_path)
  end

  private

  def resolve_resource_into_path(base_path, resource)
    File.expand_path File.join(base_path, resource)
  end

  def resolve_status_code base_path, file_path
    if file_path.index(base_path) == 0  # запрашиваемый путь внутри public
      if File.file?(file_path)          # и файл по данному пути существует
        '200 OK'
      else                              # файла с таким именем не существует
        '404 Not Found'
      end
    else                                # запрашиваемый путь за пределами public
      '403 Forbidden'
    end
  end

  def form_headers(status, file_path)
    headers = [
      "HTTP/1.1 #{status}",
      "Date: #{ Time.now }",
      'Server: WebServerLight',
      'Cache-Control: no-cache'
    ]

    if status == '200'
      headers << "Content-Type: #{define_content_type file_path}"
    else
      headers << "Content-Type: text/html"
    end

    # base_name = File.basename file_path
    # unless base_name == 'index.html'
    # headers.push "content-disposition: attachment; filename=\"#{base_name}\""
    # headers.push "content-length: #{File.size(file_path)}"
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
