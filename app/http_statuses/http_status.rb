# -*- encoding : utf-8 -*-

module WebServerLight
  class HTTPStatus
    attr_reader :code, :full_code

    def initialize(code, full_code)
      @code      = code
      @full_code = full_code
    end

    def template
      File.join(Config::AppData.templates_path, "#{code}.html.erb")
    end
  end
end
