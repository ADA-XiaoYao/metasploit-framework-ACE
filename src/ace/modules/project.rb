#
# MSF-ACE - Project Management Module
#
# This module handles all commands related to project management.
# It acts as a user-friendly wrapper around Metasploit's built-in
# 'workspace' functionality.
#

# All functional modules must be defined within the Ace::Modules namespace.
module Ace
  module Modules
    class Project

      # Readers for instance variables that might be useful for other modules.
      attr_reader :name, :description, :framework

      def initialize(framework, opts)
        # The name of the module, used by the command dispatcher.
        @name = "Project"
        # A short description, shown in the main 'ace help' menu.
        @description = "Manages projects (workspaces) and associated data."
        # Store a reference to the main Metasploit framework object.
        @framework = framework
      end

      # This is the central command handler for this module.
      # It's called by the CommandDispatcher.
      def handle_command(action, args)
        # A case statement to route the action to the correct private method.
        case action.downcase
        when 'create'
          create_project(args.first)
        when 'switch'
          switch_project(args.first)
        when 'list'
          list_projects
        when 'current'
          current_project
        when 'delete'
          delete_project(args.first)
        when 'help'
          print_module_help
        else
          print_error("Unknown action '#{action}' for the Project module.")
          print_module_help
        end
      end

      private

      # --- Action Methods ---

      def create_project(name)
        return print_error("A project name is required. Usage: ace project create <name>") if name.nil? || name.empty?

        if framework.db.find_workspace(name)
          print_error("Project '#{name}' already exists.")
        else
          framework.db.add_workspace(name)
          print_good("Project '#{name}' created successfully.")
          # Automatically switch to the newly created project for a better user experience.
          switch_project(name)
        end
      end

      def switch_project(name)
        return print_error("A project name is required. Usage: ace project switch <name>") if name.nil? || name.empty?

        workspace = framework.db.find_workspace(name)
        if workspace
          framework.db.workspace = workspace
          print_good("Switched to project '#{name}'.")
        else
          print_error("Project '#{name}' not found.")
        end
      end

      def list_projects
        print_status("Listing all available projects...")
        tbl = Rex::Text::Table.new(
          'Header'  => 'Available Projects',
          'Columns' => ['Name', 'Hosts', 'Services', 'Vulns', 'Loot']
        )
        framework.db.workspaces.each do |ws|
          # Highlight the currently active project.
          is_current = ws.name == framework.db.workspace.name ? " (*)" : ""
          tbl << ["#{ws.name}#{is_current}", ws.hosts.count, ws.services.count, ws.vulns.count, ws.loots.count]
        end
        print_line(tbl.to_s)
      end

      def current_project
        print_status("Current active project is: '#{framework.db.workspace.name}'")
      end
      
      def delete_project(name)
        return print_error("A project name is required. Usage: ace project delete <name>") if name.nil? || name.empty?
        
        # Safety check: prevent deleting the default workspace.
        if name.casecmp('default').zero?
          print_error("The 'default' project cannot be deleted.")
          return
        end
        
        workspace = framework.db.find_workspace(name)
        if workspace
          # Critical safety check: ensure the user is not deleting the project they are currently in.
          if framework.db.workspace.name == workspace.name
              print_error("Cannot delete the currently active project. Please switch to another project first.")
              return
          end
          
          # Final confirmation from the user.
          if Rex::Ui::Text::Prompt.prompt_yesno("Are you sure you want to permanently delete the project '#{name}' and all its data (hosts, vulns, etc.)?")
            framework.db.delete_workspace(workspace)
            print_good("Project '#{name}' has been deleted.")
          else
            print_status("Project deletion cancelled.")
          end
        else
          print_error("Project '#{name}' not found.")
        end
      end

      # Prints the help menu specific to this module.
      def print_module_help
        print_line
        print_line "Project Module Help"
        print_line "-------------------"
        print_line "This module is a wrapper around Metasploit's workspaces."
        print_line
        print_line "Usage: ace project <action> [arguments...]"
        print_line
        print_line "Available Actions:"
        tbl = Rex::Text::Table.new(
            'Header' => '',
            'Columns' => ['Action', 'Description']
        )
        tbl << ['create <name>', 'Creates a new project and switches to it.']
        tbl << ['switch <name>', 'Switches to an existing project.']
        tbl << ['list', 'Lists all available projects and their stats.']
        tbl << ['current', 'Shows the name of the current active project.']
        tbl << ['delete <name>', 'Deletes a project (cannot be the active one).']
        tbl << ['help', 'Shows this help menu.']
        print_line(tbl.to_s)
        print_line
      end
    end
  end
end
