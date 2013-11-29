require 'http_statuses/http_status'

class HTTPStatus200 < HTTPStatus
  def initialize
    super(200, '200 OK')
  end

  def template
    nil
  end
end