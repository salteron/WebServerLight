# -*- encoding : utf-8 -*-

require 'app/response'
require 'app/http_statuses/http_status'
require 'app/http_statuses/http_status_200'
require 'app/http_statuses/http_status_403'
require 'app/http_statuses/http_status_404'
require 'app/http_statuses/http_status_500'

module WebServerLight
  module Tools
    class HTTPResponseGenerator
      def generate_from_uri(uri, client_socket)
        path      = resolve_resource_into_path(uri)
        status    = resolve_status_code(path)

        file_path = status.is_a?(HTTPStatus::HTTPStatus200) ? path : status.template

        generate_from_status(status, client_socket, file_path)
      rescue Exceptions::HTTP500Exception
        g_500(client_socket)
      end

      def generate_from_status(status, client_socket, file_path = status.template)
        head = form_head(status, file_path)
        body = file_path

        Response.new(client_socket, status, head, body)
      end

      def g_500(client_socket)
        generate_from_status(HTTPStatus::HTTPStatus500.new, client_socket)
      end

      private

      def resolve_resource_into_path(resource)
        case
        when resource.empty?
          index_path
        when resource == 'stats'
          stats_path
        when resource == 'favicon.ico'
          favicon_path
        else
          File.expand_path(File.join(Config::AppData.public_path, resource)).strip
        end
      end

      def resolve_status_code(path)
        if File.file?(path)         # Это файл и он существует
          if permitted?(path)       # и находится внутри public'а
            HTTPStatus::HTTPStatus200.new
          else                      # но находится снаружи public'а
            HTTPStatus::HTTPStatus403.new
          end
        else                        # либо не файл, либо несуществующий файл
          HTTPStatus::HTTPStatus404.new
        end
      end

      def permitted?(file_path)
        path_idx = file_path.index(Config::AppData.public_path)
        service_paths.include?(file_path) || (path_idx && path_idx.zero?)
      end

      def form_head(status, file_path)
        headers = [
          "HTTP/1.1 #{status.full_code}",
          "Date: #{ Time.now }",
          'Server: WebServerLight',
          'Cache-Control: no-cache'
        ]

        if status.is_a?(HTTPStatus::HTTPStatus200)
          headers << "Connection: keep-alive"
          headers << "Content-Type: #{define_content_type file_path}"
        else
          headers << "Connection: close"
          headers << "Content-Type: text/html"
        end

        # base_name = File.basename file_path
        # unless base_name == 'index.html'
        #   headers.push "content-disposition: attachment; filename=\"#{base_name}\""
        #   headers.push "content-length: #{File.size(file_path)}"
        # end

        headers.last << "\r\n\r\n"
        headers.join("\r\n")
      end

      def define_content_type(path)
        ext = File.extname(path)
        return 'text/html'  if ext == '.html' || ext == '.htm' || ext == '.erb'
        return 'text/plain' if ext == '.txt'
        return 'text/css'   if ext == '.css'
        return 'image/jpeg' if ext == '.jpeg' || ext == '.jpg'
        return 'image/gif'  if ext == '.gif'
        return 'image/bmp'  if ext == '.bmp'
        return 'image/x-icon' if ext == '.ico'
        return 'text/plain' if ext == '.rb'
        return 'text/xml'   if ext == '.xml'
        return 'text/xml'   if ext == '.xsl'

        'text/html'
      end

      def service_paths
        [index_path, stats_path, favicon_path]
      end

      def index_path
        File.join(Config::AppData.templates_path, 'index.html.erb')
      end

      def stats_path
        index_path
      end

      def favicon_path
        File.join(Config::AppData.templates_path, 'favicon.ico')
      end
    end
  end
end
