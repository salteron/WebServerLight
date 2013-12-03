# -*- encoding : utf-8 -*-

module WebServerLight
  module Tools
    class HTTPInputParser
      HTTP_REQUEST_LINE_REGEXP = %r{
          ^GET            # http method
          \s+             # whitespaces
          \/(?<uri>\S*)   # uri
        }xi

      # returns uri if input contains vaid request line
      # nil otherwise
      def parse_uri(input)
        lines = parse_input input
        extract_uri lines
      end

      private

      def parse_input(input)
        input.split("\n")
      end

      def extract_uri(lines)
        request_line = lines[0]

        match = HTTP_REQUEST_LINE_REGEXP.match(request_line)
        match ? (match[:uri] || '') : nil
      end
    end
  end
end
