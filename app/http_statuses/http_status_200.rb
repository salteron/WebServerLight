# -*- encoding : utf-8 -*-

module WebServerLight
  class HTTPStatus::HTTPStatus200 < HTTPStatus
    def initialize
      super(200, '200 OK')
    end

    def template
      ''
    end
  end
end
