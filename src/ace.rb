#
# MSF-ACE (Advanced Command-line Environment) - Main Plugin Entrypoint
#
# This is the primary file loaded by Metasploit when the user runs 'load ace'.
# Its main responsibilities are:
#   1. Setting up the Ruby load path to find our 'ace' sub-directories.
#   2. Requiring the core components: ModuleLoader and CommandDispatcher.
#   3. Defining the main plugin class that Metasploit interacts with.
#   4. Setting up the necessary database tables for advanced features.
#   5. Initializing all ACE modules and registering the command dispatcher.
#

# Add our custom 'ace' directory to Ruby's load path.
# This allows us to use `require 'core/module_loader'` instead of complex relative paths.
$:.unshift(File.join(File.dirname(__FILE__), 'ace'))

# Load the core components of the ACE framework.
require 'core/module_loader'
require 'core/command_dispatcher'

# Define the main plugin class that Metasploit will instantiate.
class MetasploitModule < Msf::Plugin

  # This method is called when the plugin is loaded.
  def initialize(framework, opts)
    super

    # Set up the database before loading modules that might depend on it.
    setup_database

    # Initialize and load all ACE functional modules (e.g., Project, Task, Team).
    Ace::Core::ModuleLoader.load_modules(framework, opts)

    # Add the main 'ace' command dispatcher to the msfconsole.
    add_console_dispatcher(Ace::Core::CommandDispatcher)
  end

  # This method is called when the plugin is unloaded (e.g., with 'unload ace').
  def cleanup
    # Remove the 'ace' command dispatcher to clean up the console.
    remove_console_dispatcher('ACE')
    print_status("MSF-ACE has been unloaded.")
  end

  # Returns the official name of the plugin.
  def name
    "MSF-ACE"
  end

  # Returns a short description of the plugin.
  def desc
    "Brings Metasploit Pro's functionality to the command line. Type 'ace help' to start."
  end

  private

  # This method handles simple database migrations for ACE.
  # It checks for the existence of custom tables and creates them if they are missing.
  def setup_database
    # Ensure the database is active and connected.
    unless framework.db.active
      print_error("Database not connected. ACE features like 'team' will not work.")
      print_error("Please connect to a database (e.g., 'db_connect') and reload the plugin.")
      return
    end

    # --- Migration for 'ace_users' table ---
    begin
      # A simple way to check if the table exists is to query it.
      framework.db.execute("SELECT 1 FROM ace_users LIMIT 1")
    rescue ActiveRecord::StatementInvalid
      # This error means the table does not exist, so we create it.
      print_status("ACE 'ace_users' table not found, creating it...")
      begin
        framework.db.execute <<-SQL
          CREATE TABLE ace_users (
            id SERIAL PRIMARY KEY,
            username VARCHAR(255) UNIQUE NOT NULL,
            created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
          );
        SQL
        print_good("Table 'ace_users' created successfully.")
      rescue => e
        print_error("Failed to create 'ace_users' table: #{e.message}")
      end
    end

    # You can add more migration checks for future tables here.
    # Example:
    # begin
    #   framework.db.execute("SELECT 1 FROM ace_project_metadata LIMIT 1")
    # rescue ActiveRecord::StatementInvalid
    #   print_status("Creating 'ace_project_metadata' table...")
    #   # ... CREATE TABLE SQL ...
    # end
  end

end
