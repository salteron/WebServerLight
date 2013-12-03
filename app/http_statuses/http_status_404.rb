# -*- encoding : utf-8 -*-

module WebServerLight
  class HTTPStatus::HTTPStatus404 < HTTPStatus
    def initialize
      super(404, '404 Not Found')
    end
  end
end
