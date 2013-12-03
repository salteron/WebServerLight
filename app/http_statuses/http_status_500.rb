# -*- encoding : utf-8 -*-

require 'http_statuses/http_status'

class HTTPStatus500 < HTTPStatus
  def initialize
    super(500, '500 Internal Server Error')
  end

  def template
    File.join(AppData.templates_path, "500.html")
  end
end
