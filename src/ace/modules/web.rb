# msf-ace/src/ace/modules/web.rb
module Ace
  module Modules
    class Web
      attr_reader :name, :description, :framework

      def initialize(framework, opts)
        @name = "Web"
        @description = "Wrapper for common web application scanning tasks."
        @framework = framework
      end

      def handle_command(action, args)
        case action.downcase
        when 'scan'
          scan_web(args.first)
        else
          print_module_help
        end
      end

      private

      def scan_web(url)
        return print_error("URL required. e.g., http://example.com") if url.nil?
        
        # 解析URL获取主机和端口
        uri = URI.parse(url)
        rhost = uri.host
        rport = uri.port
        ssl = uri.scheme == 'https'

        print_status("Starting basic web scan against #{url}...")

        # 定义要运行的扫描模块列表
        scan_modules = [
          'auxiliary/scanner/http/dir_scanner',
          'auxiliary/scanner/http/options',
          'auxiliary/scanner/http/title'
        ]

        scan_modules.each do |mod_name|
          print_status("Running module: #{mod_name}")
          mod = framework.modules.create(mod_name)
          opts = {
            'RHOSTS' => rhost,
            'RPORT' => rport,
            'SSL' => ssl
          }
          mod.run_simple(
            'LocalInput'  => framework.input,
            'LocalOutput' => framework.output,
            'OptionStr'   => opts.map { |k,v| "#{k}=#{v}" }.join(',')
          )
        end
        print_good("Web scan finished.")
      end

      def print_module_help
        print_line "Web Module: ace web scan <url>"
      end
    end
  end
end
