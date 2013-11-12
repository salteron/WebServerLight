require 'webrick'

class FakeResourceSender
  def send_resource request
    puts "Sending file #{request.resource} ..."
    sleep 10
    puts "File #{request.resource} has been sent"
  end
end

class HTTPResourceSender

  def send_resource request

    request.client.puts form_headers(request)

    File.open(request.file_path, 'r') do |src|
      until src.eof?
        request.client.write src.read(256)
      end
    end
  end

  def form_headers request
    headers = [
        "HTTP/1.1 200 OK",
        "Date: #{ Time.now }",
        "Server: WebServerLight",
        "Content-Type: #{define_content_type request.file_path}",
        "Cache-Control: no-cache"
    ]

    base_name = File.basename request.file_path
    unless base_name == 'index.html'
      #headers.push "content-disposition: attachment; filename=\"#{base_name}\""
      #headers.push "content-length: #{File.size(request.file_path)}"
    end

    headers.last << "\r\n\r\n"
    headers.join("\r\n")
  end

  def define_content_type(path)
    ext = File.extname(path)
    return "text/html"  if ext == ".html" or ext == ".htm"
    return "text/plain" if ext == ".txt"
    return "text/css"   if ext == ".css"
    return "image/jpeg" if ext == ".jpeg" or ext == ".jpg"
    return "image/gif"  if ext == ".gif"
    return "image/bmp"  if ext == ".bmp"
    return "image/x-icon" if ext == ".ico"
    return "text/plain" if ext == ".rb"
    return "text/xml"   if ext == ".xml"
    return "text/xml"   if ext == ".xsl"

    "text/html"
  end

=begin

  def send_resource request
    begin
      response = WEBrick::HTTPResponse.new(
          :HTTPVersion => '1.1'
      )

      filename = File.basename request.file_path

      unless filename == 'index.html'
        response['Content-Disposition'] = "attachment; filename=\"#{filename}\""
        response['Content-Length']      = File.size(request.file_path)
      end

      response.body = File.read request.file_path

      response.send_response request.client
    #rescue => e
    #  puts e.message
    ensure
      request.client.close
    end
  end
=end
end