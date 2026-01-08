# msf-ace/src/ace/modules/pivot.rb
module Ace
  module Modules
    class Pivot
      attr_reader :name, :description, :framework

      def initialize(framework, opts)
        @name = "Pivot"
        @description = "Simplifies creation of network pivots."
        @framework = framework
      end

      def handle_command(action, args)
        case action.downcase
        when 'setup'
          setup_pivot(args.first)
        when 'list'
          list_pivots
        else
          print_module_help
        end
      end

      private

      def setup_pivot(session_id)
        return print_error("Session ID required.") if session_id.nil?
        
        session = framework.sessions[session_id.to_i]
        unless session
          print_error("Session #{session_id} not found.")
          return
        end

        print_status("Setting up pivot through session #{session.sid}...")
        
        # 自动探测子网
        subnets = []
        session.load_stdapi
        session.net.config.each_route do |route|
            next if route.subnet == '0.0.0.0'
            subnets << "#{route.subnet}/#{route.netmask}"
        end

        if subnets.empty?
            print_error("Could not automatically determine subnets for session #{session.sid}.")
            return
        end

        print_status("Found subnets: #{subnets.join(', ')}. Adding routes...")

        # 使用 autoroute 脚本添加路由
        autoroute = framework.modules.create('post/multi/manage/autoroute')
        autoroute.run_simple(
            'SESSION' => session.sid,
            'SUBNET' => subnets.join(',')
        )
        print_good("Pivot configured. Use 'run' with modules to scan through the pivot.")
      end

      def list_pivots
        framework.events.on_ui_command('route print')
      end

      def print_module_help
        print_line "Pivot Module: ace pivot <setup|list>"
      end
    end
  end
end
