#
# MSF-ACE - Professional Reporting Module
#
# This module generates professional HTML reports from the data
# collected in the current Metasploit project workspace.
#

require 'erb' # For HTML templating
require 'fileutils'

module Ace
  module Modules
    class Report

      attr_reader :name, :description, :framework

      def initialize(framework, opts)
        @name = "Report"
        @description = "Generates professional reports from project data."
        @framework = framework
        
        # Define a directory for custom report templates
        @templates_dir = File.join(Msf::Config.user_config_directory, 'ace_report_templates')
        FileUtils.mkdir_p(@templates_dir)
      end

      # --- Command Handling ---

      def handle_command(action, args)
        case action.downcase
        when 'generate'
          generate_report(args)
        when 'templates'
          list_templates
        when 'help'
          print_module_help
        else
          print_error("Unknown action '#{action}' for the Report module.")
          print_module_help
        end
      end

      private

      # --- Main Action Methods ---

      def generate_report(args)
        # Default options
        options = {
          type: 'html',
          output: File.join(Dir.tmpdir, "ace_report_#{Time.now.to_i}.html"),
          template: 'default'
        }

        # Simple command-line option parsing
        args.each_with_index do |arg, i|
          case arg
          when '--type'
            options[:type] = args[i+1] if args[i+1]
          when '--output'
            options[:output] = args[i+1] if args[i+1]
          when '--template'
            options[:template] = args[i+1] if args[i+1]
          end
        end

        unless options[:type] == 'html'
          print_error("Unsupported report type: '#{options[:type]}'. Only 'html' is currently supported.")
          return
        end

        print_status("Generating report with the following options:")
        print_line("  - Type: #{options[:type]}")
        print_line("  - Output: #{options[:output]}")
        print_line("  - Template: #{options[:template]}")
        
        # 1. Gather data from the database
        print_status("Gathering data from project '#{framework.db.workspace.name}'...")
        report_data = gather_report_data

        # 2. Load the ERB template
        template_content = load_template(options[:template])
        return unless template_content

        # 3. Render the template with the data
        print_status("Rendering HTML content...")
        begin
          renderer = ERB.new(template_content, trim_mode: "-")
          html_output = renderer.result(binding) # 'binding' makes local variables available in the template
        rescue => e
          print_error("Failed to render template: #{e.message}")
          return
        end

        # 4. Write to file
        begin
          File.write(options[:output], html_output)
          print_good("Report successfully generated: #{options[:output]}")
        rescue => e
          print_error("Failed to write report to file: #{e.message}")
        end
      end

      def list_templates
        print_status("Available Report Templates:")
        print_line("  - default (Built-in)")
        
        custom_templates = Dir.glob(File.join(@templates_dir, '*.erb'))
        unless custom_templates.empty?
          print_status("Custom templates in '#{@templates_dir}':")
          custom_templates.each do |t|
            print_line("  - #{File.basename(t, '.erb')}")
          end
        end
      end

      # --- Helper Methods ---

      def gather_report_data
        ws = framework.db.workspace
        {
          project_name: ws.name,
          generated_at: Time.now.strftime("%Y-%m-%d %H:%M:%S"),
          hosts: ws.hosts.order(:address),
          vulns: ws.vulns.order('hosts.address, services.port'),
          creds: ws.creds.order(:created_at),
          loots: ws.loots.order(:created_at),
          stats: {
            host_count: ws.hosts.count,
            vuln_count: ws.vulns.count,
            cred_count: ws.creds.count,
            loot_count: ws.loots.count
          }
        }
      end

      def load_template(template_name)
        # First, check for a custom template
        custom_path = File.join(@templates_dir, "#{template_name}.erb")
        if File.exist?(custom_path)
          print_status("Loading custom template: '#{template_name}'")
          return File.read(custom_path)
        end

        # If not found, check for built-in templates
        if template_name == 'default'
          print_status("Loading built-in 'default' template.")
          return DEFAULT_HTML_TEMPLATE
        end

        print_error("Template '#{template_name}' not found.")
        nil
      end

      def print_module_help
        print_line
        print_line "Report Module Help"
        print_line "------------------"
        print_line "Generates reports from the current project's data."
        print_line
        print_line "Usage: ace report <action> [options...]"
        print_line
        print_line "Available Actions:"
        tbl = Rex::Text::Table.new('Header' => '', 'Columns' => ['Action', 'Description'])
        tbl << ['generate', 'Generates a new report.']
        tbl << ['templates', 'Lists available report templates.']
        tbl << ['help', 'Shows this help menu.']
        print_line(tbl.to_s)
        print_line
        print_line "Generate Options:"
        opts_tbl = Rex::Text::Table.new('Header' => '', 'Columns' => ['Option', 'Description'])
        opts_tbl << ['--type <format>', "Report format (default: html)."]
        opts_tbl << ['--output <path>', "File path to save the report."]
        opts_tbl << ['--template <name>', "Template to use (default: default)."]
        print_line(opts_tbl.to_s)
        print_line
        print_line "Example: ace report generate --output /tmp/my_report.html"
      end

      # --- Default HTML Template ---
      # Using a HEREDOC to store the template string inside the script
      DEFAULT_HTML_TEMPLATE = <<-ERB.freeze
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>MSF-ACE Report: <%= report_data[:project_name] %></title>
    <style>
        body { font-family: sans-serif; margin: 2em; color: #333; }
        h1, h2, h3 { color: #d9534f; border-bottom: 2px solid #f0f0f0; padding-bottom: 5px; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 2em; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .summary { background-color: #f9f9f9; padding: 1em; border-radius: 5px; }
        .summary-box { display: inline-block; text-align: center; padding: 1em; margin: 0 1em; }
        .summary-box .count { font-size: 2em; font-weight: bold; }
    </style>
</head>
<body>
    <h1>Penetration Test Report</h1>
    <p>Generated by MSF-ACE on <%= report_data[:generated_at] %></p>

    <h2>Executive Summary</h2>
    <div class="summary">
        <h3>Project: <%= report_data[:project_name] %></h3>
        <div class="summary-box">
            <div class="count"><%= report_data[:stats][:host_count] %></div>
            <div>Hosts</div>
        </div>
        <div class="summary-box">
            <div class="count"><%= report_data[:stats][:vuln_count] %></div>
            <div>Vulnerabilities</div>
        </div>
        <div class="summary-box">
            <div class="count"><%= report_data[:stats][:cred_count] %></div>
            <div>Credentials</div>
        </div>
        <div class="summary-box">
            <div class="count"><%= report_data[:stats][:loot_count] %></div>
            <div>Loot</div>
        </div>
    </div>

    <h2>Hosts</h2>
    <table>
        <tr><th>IP Address</th><th>OS</th><th>Purpose</th><th>State</th></tr>
        <% report_data[:hosts].each do |host| %>
        <tr>
            <td><%= host.address %></td>
            <td><%= host.os_name %> <%= host.os_flavor %></td>
            <td><%= host.purpose %></td>
            <td><%= host.state %></td>
        </tr>
        <% end %>
    </table>

    <h2>Vulnerabilities</h2>
    <table>
        <tr><th>Host</th><th>Port</th><th>Service</th><th>Vulnerability Name</th></tr>
        <% report_data[:vulns].each do |vuln| %>
        <tr>
            <td><%= vuln.host.address %></td>
            <td><%= vuln.service&.port %></td>
            <td><%= vuln.service&.name %></td>
            <td><%= vuln.name %></td>
        </tr>
        <% end %>
    </table>

    <h2>Credentials Found</h2>
    <table>
        <tr><th>Host</th><th>Port</th><th>Service</th><th>Username</th><th>Password/Hash</th></tr>
        <% report_data[:creds].each do |cred| %>
        <tr>
            <td><%= cred.service.host.address %></td>
            <td><%= cred.service.port %></td>
            <td><%= cred.service.name %></td>
            <td><%= cred.public %></td>
            <td><%= cred.private %></td>
        </tr>
        <% end %>
    </table>
</body>
</html>
      ERB
    end
  end
end
