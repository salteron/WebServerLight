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
    headers = ["http/1.1 200 ok",
               "connection: keep-alive",
               "date: #{ Time.now }",
               "server: WebServerLight"
               ]

    unless request.resource == '/index.html'
      filename = File.basename request.file_path
      headers.push "content-length: #{filename.size}"
      headers.push "content-disposition: attachment; filename=\"#{filename}"
    end

    headers.last << "\r\n\r\n"
    headers.join("\r\n")

    request.client.puts headers

    File.open(request.file_path, 'r') do |src|
      request.client.puts src.read
    end
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