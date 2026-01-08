#
# MSF-ACE - Core Command Dispatcher
#
# This class is the central hub for all 'ace' commands entered into msfconsole.
# It is responsible for:
#   1. Registering the top-level 'ace' command.
#   2. Parsing the user's input to identify the target module and action.
#   3. Routing the command to the appropriate functional module for execution.
#   4. Displaying the main help menu.
#

module Ace
  module Core
    class CommandDispatcher
      # This mixin provides the necessary methods to interact with the msfconsole UI.
      include Msf::Ui::Console::CommandDispatcher

      # Returns the name of the command dispatcher group.
      def name
        "ACE"
      end

      # Registers the commands that this dispatcher will handle.
      # In this case, it's only the top-level 'ace' command.
      def commands
        {
          "ace" => "MSF-ACE root command. Use 'ace help' for a list of modules."
        }
      end

      # This is the main method that gets executed when a user types 'ace ...'.
      def cmd_ace(*args)
        # If no arguments are given, or if 'help' is the first argument, show the main help menu.
        if args.empty? || args[0].casecmp('help').zero?
          print_help
          return
        end

        # The first argument is the module name (e.g., 'project').
        module_name = args.shift
        # The second argument is the action for that module (e.g., 'create').
        # If no action is provided, we default to 'help' for that module.
        action_name = args.shift || 'help'

        # Find the loaded module that matches the requested module name.
        handler_module = Ace::Core::ModuleLoader.modules.find { |m| m.name.casecmp(module_name).zero? }

        # If no matching module is found, print an error and show the main help.
        if handler_module.nil?
          print_error("Unknown ACE module: '#{module_name}'.")
          print_help
          return
        end

        # If a module is found, call its 'handle_command' method, passing the
        # action and any remaining arguments.
        handler_module.handle_command(action_name, args)
      end

      private

      # Prints the main help menu, listing all available functional modules.
      def print_help
        print_line
        print_line "MSF-ACE - Advanced Command-line Environment"
        print_line "=========================================="
        print_line "Usage: ace <module> <action> [options...]"
        print_line
        print_line "Available Modules:"
        
        # Create a formatted table for better readability.
        tbl = Rex::Text::Table.new(
          'Header'  => '',
          'Columns' => ['Module', 'Description']
        )
        
        # Populate the table with information from each loaded module.
        Ace::Core::ModuleLoader.modules.each do |m|
          tbl << [m.name.downcase, m.description]
        end
        
        print_line(tbl.to_s)
        print_line
        print_line "For help on a specific module, type: ace <module> help"
        print_line
      end

    end
  end
end

