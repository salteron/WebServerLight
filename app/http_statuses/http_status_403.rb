# -*- encoding : utf-8 -*-

require 'http_statuses/http_status'

class HTTPStatus403 < HTTPStatus
  def initialize
    super(403, '403 Forbidden')
  end
end
