# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    class HttpClient
      class << self
        def request(url, method, payload: nil, headers: {}, config: {})
          uri = URI(url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == "https")

          # Set timeout if provided
          if config[:timeout]
            timeout_value = config[:timeout].to_f
            http.open_timeout = timeout_value
            http.read_timeout = timeout_value
          end

          request = build_request(method, uri, payload, headers)
          http.request(request)
        end

        private

        def build_request(method, uri, payload, headers)
          request_class = case method.upcase
                          when Constants::HTTP_GET then Net::HTTP::Get
                          when Constants::HTTP_POST then Net::HTTP::Post
                          when Constants::HTTP_PUT then Net::HTTP::Put
                          when Constants::HTTP_PATCH then Net::HTTP::Patch
                          when Constants::HTTP_DELETE then Net::HTTP::Delete
                          else raise ArgumentError, "Unsupported HTTP method: #{method}"
                          end

          request = request_class.new(uri)
          headers.each { |key, value| request[key] = value }
          request.body = payload.to_json if payload && %w[POST PUT PATCH].include?(method.upcase)
          request
        end
      end
    end
  end
end
