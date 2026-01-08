#
# MSF-ACE - Core Module Loader
#
# This class is responsible for dynamically discovering and loading all
# functional modules located in the 'ace/modules/' directory.
# It acts as a central registry for all available ACE features.
#

module Ace
  module Core
    class ModuleLoader

      # This class-level instance variable will hold all the instantiated module objects.
      # Using '||=' ensures it's initialized only once as an empty array.
      def self.modules
        @modules ||= []
      end

      # The main method that finds, requires, and instantiates all functional modules.
      # This is called once when the main 'ace.rb' plugin is loaded.
      def self.load_modules(framework, opts)
        # Construct the path to the modules directory.
        # This is more robust than a hardcoded path.
        modules_path = File.join(File.dirname(__FILE__), '..', '..', 'modules', '*.rb')

        # Use Dir.glob to find all files ending in .rb in the modules directory.
        Dir[modules_path].each do |file|
          begin
            # 'require' the found module file, which makes its class definition available.
            require file

            # Derive the class name from the filename.
            # e.g., 'project.rb' -> 'Project'
            module_name = File.basename(file, '.rb').capitalize

            # Get the actual class constant (e.g., Ace::Modules::Project).
            # This assumes all modules follow the 'Ace::Modules::ClassName' convention.
            module_class = Ace::Modules.const_get(module_name)

            # Instantiate the module class, passing the framework and opts objects,
            # and add the new object to our central registry.
            self.modules << module_class.new(framework, opts)

            # Provide feedback to the user that the module was loaded.
            print_good("ACE module '#{module_name}' loaded.")

          rescue => e
            # If anything goes wrong (e.g., syntax error in a module file),
            # print a helpful error message instead of crashing.
            print_error("Failed to load ACE module from #{file}: #{e.message}")
            # For debugging, you might want to see the backtrace:
            # puts e.backtrace.join("\n")
          end
        end
      end

    end
  end
end
