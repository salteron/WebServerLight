# -*- encoding : utf-8 -*-

module WebServerLight
  class HTTPStatus::HTTPStatus500 < HTTPStatus
    def initialize
      super(500, '500 Internal Server Error')
    end

    def template
      File.join(Config::AppData.templates_path, "500.html")
    end
  end
end
