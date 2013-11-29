require 'http_statuses/http_status'

class HTTPStatus404 < HTTPStatus
  def initialize
    super(404, '404 Not Found')
  end
end
