class HTTPStatus
  attr_reader :code, :full_code

  def initialize(code, full_code)
    @code      = code
    @full_code = full_code
  end

  def template
    File.join(AppData.templates_path, "#{code}.html.erb")
  end
end
