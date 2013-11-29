require 'http_statuses/http_status'

class HTTPStatus500 < HTTPStatus
  def initialize
    super(500, '500 Internal Server Error')
  end
end