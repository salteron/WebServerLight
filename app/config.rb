# -*- encoding : utf-8 -*-

require 'app_data'

DEFAULT_PUBLIC_PATH = File.expand_path("#{File.dirname(__FILE__)}/../public")

AppData.config do
  param :num_of_workers, :port
  param :public_path, :templates_path

  param :request_max_service,  :response_max_idle
  param :max_connections

  #######################

  num_of_workers       5
  port                 3000
  public_path          DEFAULT_PUBLIC_PATH # путь до места хранения
                                           # раздаваемых файлов

  templates_path       File.expand_path('html') # путь до шаблонов:
                                                # шаблоны статусов, index

  request_max_service  2   # предел времени ожидания запроса от клиента
  response_max_idle    1   # таймаут бездействия клиента во время передачи ответа

  max_connections      10   # максимальное число клиентов, обрабатываемых
                           # конкурентно воркером; при достижении лимита,
                           # воркер отвергает новых клиентов.
end
