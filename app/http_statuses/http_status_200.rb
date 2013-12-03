# -*- encoding : utf-8 -*-

require 'http_statuses/http_status'

class HTTPStatus200 < HTTPStatus
  def initialize
    super(200, '200 OK')
  end

  def template
    ''
  end
end
