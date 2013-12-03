# -*- encoding : utf-8 -*-

module WebServerLight
  class HTTPStatus::HTTPStatus403 < HTTPStatus
    def initialize
      super(403, '403 Forbidden')
    end
  end
end
