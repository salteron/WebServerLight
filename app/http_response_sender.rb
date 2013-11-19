# -*- encoding : utf-8 -*-

class HTTPResponseSender
  def send_response(response)
    response.client.puts response.headers
    
    if response.status == '200 OK'
      file = response.file_path
    else
      file = "html/#{response.status[0..2]}.html"
    end

    File.open(file, 'r') do |src|
      response.client.write src.read(256) until src.eof?
    end
  end
end
