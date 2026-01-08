# msf-ace/src/ace/modules/team.rb
module Ace
  module Modules
    class Team
      attr_reader :name, :description, :framework

      def initialize(framework, opts)
        @name = "Team"
        @description = "Manages users for collaboration."
        @framework = framework
      end

      def handle_command(action, args)
        case action.downcase
        when 'adduser'
          add_user(args.first)
        when 'listusers'
          list_users
        else
          print_module_help
        end
      end

      private

      def add_user(username)
        return print_error("Username required.") if username.nil?
        begin
          framework.db.execute("INSERT INTO ace_users (username, created_at) VALUES ($1, $2)", [username, Time.now])
          print_good("User '#{username}' added.")
        rescue ActiveRecord::RecordNotUnique
          print_error("User '#{username}' already exists.")
        rescue => e
          print_error("Failed to add user: #{e.message}")
        end
      end

      def list_users
        users = framework.db.execute("SELECT username, created_at FROM ace_users ORDER BY created_at").to_a
        tbl = Rex::Text::Table.new('Header' => 'ACE Users', 'Columns' => ['Username', 'Created At'])
        users.each { |u| tbl << [u['username'], u['created_at']] }
        print_line(tbl.to_s)
      end

      def print_module_help
        print_line "Team Module: ace team <adduser|listusers>"
      end
    end
  end
end
