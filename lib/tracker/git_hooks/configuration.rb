require 'yaml'

class Hash
  def symbolize_keys
    inject({}) do |options, (key, value)|
      options[(key.to_sym rescue key) || key] = value
      options
    end
  end
end

module Tracker::GitHooks
  class Configuration
    @@config = nil
    @@users = nil

    REQUIRED_KEYS = [:repository_path, :project_number]

    class << self
      def load(config_path)
        @@config = YAML.load_file(config_path + '/general.yml').symbolize_keys
        load_users(config_path + '/users')
        check!
        @@config
      end

      def [](key)
        @@config[key]
      end

      def users
        @@users
      end

      def login(git_user_email)
        nick, user = @@users.find{|k,v| v[:email] == git_user_email}
        raise "user not found: #{git_user_email}" if user.nil?
        # Can I set ruby-pivotal-tracker values here?
        user
      end

      protected

      def load_users(dir)
        @@users = {}
        Dir.open(dir).entries.grep(/\.yml$/) do |entry|
          entry_hash = YAML.load_file(dir + '/' + entry).symbolize_keys
          @@users[entry[/^(.*)\.yml$/, 1].to_sym] = entry_hash
        end
        @@users
      end

      def check!
        missing = REQUIRED_KEYS - @@config.keys
        unless missing.empty?
          raise "Missing configuration params : #{missing.join(',')}"
        end
      end
    end
  end
end
