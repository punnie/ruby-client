require 'net/http'
require 'net/https'
require 'uri'
require 'open-uri'

module SplitIoClient
  module Api
    class Client
      def get_api(url, config, api_key, params = {})
        response = URI("#{url}?#{URI.encode_www_form(params)}").read(
          common_headers(api_key, config).merge(proxy: config.proxy)
        )

        config.logger.debug("GET #{url} proxy: #{proxy_status(config)}") if config.debug_enabled

        response
      rescue StandardError => e
        config.logger.warn("#{e}\nURL:#{url}\nparams:#{params}")

        false
      end

      def new_post_api(url, config, api_key, data, headers = {}, params = {})
        uri = URI("#{url}?#{URI.encode_www_form(params)}")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'

        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data(data)
        common_headers(api_key, config).each do |name, value|
          request[name] = value
        end

        response = http.request(request)

        if config.transport_debug_enabled
          config.logger.debug("POST #{url} #{request.body}")
        elsif config.debug_enabled
          config.logger.debug("POST #{url}")
        end

        response
      rescue StandardError => e
        config.logger.warn("#{e}\nURL:#{url}\ndata:#{data}\nparams:#{params}")

        false
      end

      def post_api(url, config, api_key, data, headers = {}, params = {})
        api_client.post(url) do |req|
          req.headers = common_headers(api_key, config)
            .merge('Content-Type' => 'application/json')
            .merge(headers)

          req.body = data.to_json

          req.options[:timeout] = config.read_timeout
          req.options[:open_timeout] = config.connection_timeout

          if config.transport_debug_enabled
            config.logger.debug("POST #{url} #{req.body}")
          elsif config.debug_enabled
            config.logger.debug("POST #{url}")
          end
        end
      rescue StandardError => e
        config.logger.warn("#{e}\nURL:#{url}\ndata:#{data}\nparams:#{params}")

        false
      end

      private

      def api_client
        @api_client ||= Faraday.new do |builder|
          # builder.use FaradayMiddleware::Gzip
          # builder.adapter :net_http_persistent
          builder.adapter :net_http
        end
      end

      def common_headers(api_key, config)
        {
          'Authorization' => "Bearer #{api_key}",
          'SplitSDKVersion' => "#{config.language}-#{config.version}",
          'SplitSDKMachineName' => config.machine_name,
          'SplitSDKMachineIP' => config.machine_ip,
          'Referer' => referer(config)
        }
      end

      def referer(config)
        result = "#{config.language}-#{config.version}"

        result = "#{result}::#{SplitIoClient::SplitConfig.get_hostname}" unless SplitIoClient::SplitConfig.get_hostname == 'localhost'

        result
      end

      def proxy_status(config)
        config.proxy == true ? 'using ENV settings' : config.proxy
      end
    end
  end
end
