#
# MSF-ACE - Automation Task Module (Final Version)
#
# This module is the heart of the ACE framework's automation capabilities.
# It parses and executes predefined task chains from YAML files, with
# support for variables, conditional logic, and error handling.
#

require 'yaml'
require 'erb' # For variable substitution

module Ace
  module Modules
    class Task

      attr_reader :name, :description, :framework

      def initialize(framework, opts)
        @name = "Task"
        @description = "Manages and runs automated task chains from YAML files."
        @framework = framework
        
        @tasks_dir = File.join(Msf::Config.user_config_directory, 'ace_tasks')
        FileUtils.mkdir_p(@tasks_dir)
      end

      # --- Command Handling ---

      def handle_command(action, args)
        vars_override = parse_runtime_vars(args) # Extracts --vars and removes them from args

        case action.downcase
        when 'run'
          run_task(args.first, vars_override)
        when 'list'
          list_tasks
        when 'show'
          show_task(args.first)
        when 'define'
          define_task_interactive
        when 'help'
          print_module_help
        else
          print_error("Unknown action '#{action}' for the Task module.")
          print_module_help
        end
      end

      private

      # --- Main Action Methods ---

      def run_task(file_path, vars_override)
        full_path = find_task_file(file_path)
        return unless full_path && File.exist?(full_path)

        print_status("Loading task from '#{File.basename(full_path)}'...")
        config = parse_and_validate_yaml(full_path)
        return unless config

        variables = (config['vars'] || {}).merge(vars_override)
        
        print_good("Starting task: #{config['name'] || 'Untitled Task'}")
        print_line("-" * 50)

        # --- Task Execution Engine ---
        config['steps'].each_with_index do |step, index|
          step_name = step['name'] || "Step #{index + 1}"
          
          print_line
          print_status("Executing: #{step_name}")

          # Conditional Execution Check (run_if)
          if step['run_if']
            condition_met = evaluate_condition(step['run_if'])
            unless condition_met
              print_status("  - Skipping step due to 'run_if' condition not being met.")
              next
            end
          end

          print_status("  - Description: #{step['description']}") if step['description']
          
          # Variable Substitution
          begin
            command = substitute_variables(step['command'], variables)
            print_status("  - Command: #{command.gsub("\n", " ")}")
          rescue NameError => e
            print_error("  - Variable substitution failed: #{e.message}. Check your YAML file for undefined variables.")
            break # Stop the entire task
          end

          # Execute the command
          framework.events.on_ui_command(command)
          
          # Simple wait for command processing. A more advanced implementation
          # might use framework events to know when a command truly finishes.
          sleep(1) 
        end
        print_line("-" * 50)
        print_good("Task finished.")
      end

      def list_tasks
        print_status("Listing available tasks in '#{@tasks_dir}'...")
        tasks = Dir.glob(File.join(@tasks_dir, '*.{yml,yaml}'))
        
        if tasks.empty?
          print_status("No task files found in '#{@tasks_dir}'.")
          return
        end
        
        tbl = Rex::Text::Table.new('Header' => 'Available Tasks', 'Columns' => ['Task File', 'Description'])
        tasks.each do |task_file|
          begin
            config = YAML.load_file(task_file)
            tbl << [File.basename(task_file), config['description'] || "N/A"]
          rescue
            tbl << [File.basename(task_file), "Error parsing file."]
          end
        end
        print_line(tbl.to_s)
      end

      def show_task(file_path)
        full_path = find_task_file(file_path)
        return unless full_path && File.exist?(full_path)

        config = parse_and_validate_yaml(full_path)
        return unless config

        print_line
        print_good "Task Details: #{config['name'] || 'Untitled Task'}"
        print_line "File: #{File.basename(full_path)}"
        print_line "Author: #{config['author'] || 'N/A'}"
        print_line "Description: #{config['description'] || 'N/A'}"
        print_line "-" * 50

        print_good "Variables (Defaults):"
        if config['vars'] && !config['vars'].empty?
          config['vars'].each { |k, v| print_line "  #{k}: #{v}" }
        else
          print_line "  None"
        end
        print_line "-" * 50

        print_good "Steps:"
        config['steps'].each_with_index do |step, i|
          print_line "  [Step #{i+1}] #{step['name'] || ''}"
          print_line "    Desc: #{step['description'] || 'N/A'}"
          print_line "    Cmd:  '#{step['command'].gsub("\n", " ")}'"
          if step['run_if']
            logic = step['run_if']['logic']&.upcase || 'AND'
            print_line "    Run If (Logic: #{logic}):"
            step['run_if']['conditions'].each { |c| print_line "      - `#{c['model']}` where `#{c['where']}`" }
          else
            print_line "    Run If: Always"
          end
        end
        print_line
      end
      
      def define_task_interactive
        print_status("Interactive Task Definition Wizard (Ctrl+C to cancel)")
        
        config = { 'vars' => {}, 'steps' => [] }
        config['name'] = Rex::Ui::Text::Prompt.prompt("Task Name: ")
        config['author'] = Rex::Ui::Text::Prompt.prompt("Author: ")
        config['description'] = Rex::Ui::Text::Prompt.prompt("Description: ")

        print_status("Define variables (leave key blank to finish):")
        loop do
          key = Rex::Ui::Text::Prompt.prompt("  Variable Name (e.g., RHOSTS): ")
          break if key.empty?
          value = Rex::Ui::Text::Prompt.prompt("  Default Value for #{key}: ")
          config['vars'][key] = value
        end

        print_status("Define steps (leave name blank to finish):")
        loop do
          step = {}
          step['name'] = Rex::Ui::Text::Prompt.prompt("  Step Name: ")
          break if step['name'].empty?
          step['description'] = Rex::Ui::Text::Prompt.prompt("  Step Description: ")
          step['command'] = Rex::Ui::Text::Prompt.prompt("  Step Command: ")
          config['steps'] << step
        end

        if config['steps'].empty?
          print_error("No steps defined. Task creation cancelled.")
          return
        end

        file_name = Rex::Ui::Text::Prompt.prompt("Save task as (e.g., my_task.yml): ")
        file_name += ".yml" unless file_name.end_with?(".yml", ".yaml")
        save_path = File.join(@tasks_dir, file_name)

        if Rex::Ui::Text::Prompt.prompt_yesno("Save task to '#{save_path}'?")
          File.write(save_path, config.to_yaml)
          print_good("Task saved successfully!")
        else
          print_status("Save cancelled.")
        end
      end

      # --- Helper Methods ---

      def parse_runtime_vars(args)
        vars_override = {}
        var_arg_index = args.index('--vars')
        if var_arg_index && args[var_arg_index + 1]
          args[var_arg_index + 1].scan(/(\w+)=("([^"]*)"|'([^']*)'|(\S+))/).each do |key, _, qv1, qv2, v|
            vars_override[key] = qv1 || qv2 || v
          end
          args.slice!(var_arg_index, 2)
        end
        vars_override
      end

      def find_task_file(file_path)
        return print_error("Task file path not provided.") if file_path.nil?
        return file_path if File.exist?(file_path)
        full_path = File.join(@tasks_dir, file_path)
        return full_path if File.exist?(full_path)
        print_error("Task file not found: '#{file_path}'")
        nil
      end

      def parse_and_validate_yaml(full_path)
        begin
          config = YAML.load_file(full_path)
          unless config.is_a?(Hash) && config['steps'].is_a?(Array)
            print_error("Invalid YAML format: Must be a Hash with a 'steps' Array.")
            return nil
          end
          config
        rescue Psych::SyntaxError => e
          print_error("YAML syntax error in '#{File.basename(full_path)}': #{e.message}")
          nil
        end
      end

      def substitute_variables(command, variables)
        command_template = command.gsub(/\{\{(\w+)\}\}/, '<%=\1%>')
        binding_obj = Object.new
        variables.each do |key, value|
          binding_obj.define_singleton_method(key.to_sym) { value }
        end
        ERB.new(command_template).result(binding_obj.instance_eval { binding })
      end
      
      def evaluate_condition(run_if_config)
        unless run_if_config.is_a?(Hash) && run_if_config['conditions'].is_a?(Array)
          print_error("  - Warning: 'run_if' is malformed. Expected a Hash with a 'conditions' Array.")
          return true
        end

        logic = run_if_config['logic']&.downcase == 'or' ? :any? : :all?
        
        run_if_config['conditions'].send(logic) do |cond|
          model_name = cond['model']&.downcase
          where_clause = cond['where']
          
          unless model_name && where_clause
            print_error("  - Warning: A condition is missing 'model' or 'where'.")
            next false
          end

          model_class = case model_name
                        when 'hosts' then framework.db.hosts
                        when 'services' then framework.db.services
                        when 'vulns' then framework.db.vulns
                        when 'creds' then framework.db.creds
                        else
                          print_error("  - Invalid model '#{model_name}' in 'run_if'.")
                          next false
                        end
          
          begin
            is_met = model_class.where(where_clause).any?
            print_status("    - Condition: `#{model_name}` where `#{where_clause}` -> #{is_met ? 'MET' : 'NOT MET'}")
            is_met
          rescue ActiveRecord::StatementInvalid => e
            print_error("    - Invalid 'where' clause for '#{model_name}': #{e.message}")
            false
          end
        end
      end

      def print_module_help
        print_line
        print_line "Task Module Help"
        print_line "----------------"
        print_line "Runs automated command sequences from YAML files."
        print_line
        print_line "Usage: ace task <action> [file] [--vars \"KEY=VALUE ...\"]"
        print_line
        print_line "Available Actions:"
        tbl = Rex::Text::Table.new('Header' => '', 'Columns' => ['Action', 'Description'])
        tbl << ['run <file>', 'Parses and executes the specified task file.']
        tbl << ['list', "Lists all tasks in the default directory (#{@tasks_dir})."]
        tbl << ['show <file>', 'Displays the contents of a task file without running it.']
        tbl << ['define', 'Starts an interactive wizard to create a new task file.']
        tbl << ['help', 'Shows this help menu.']
        print_line(tbl.to_s)
        print_line
        print_line "Example: ace task run my_scan.yml --vars \"RHOSTS=10.0.0.0/24\""
      end
    end
  end
end
