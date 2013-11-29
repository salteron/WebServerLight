require 'app_data'

DEFAULT_PUBLIC_PATH = File.expand_path("#{File.dirname(__FILE__)}/../public")

AppData.config do
  param :num_of_workers, :port
  param :public_path, :templates_path

  param :request_max_service,  :response_max_idle
  param :max_connections

  #######################

  num_of_workers        1
  port                  3000
  public_path           DEFAULT_PUBLIC_PATH
  templates_path        File.expand_path('html')

  request_max_service   10  # seconds
  response_max_idle     1   # seconds

  max_connections       2   # per worker
end
