CURRENT_DIR = File.dirname(__FILE__)
VENDOR_DIR = CURRENT_DIR + '/../../vendor'
require VENDOR_DIR + '/ruby-pivotal-tracker/pivotal_tracker'
require VENDOR_DIR + '/grit/lib/grit'

module Tracker::GitHooks
  class Base
    def initialize
      @repo = Grit::Repo.new(Configuration[:repository_path])
    end
  end
end

Dir[CURRENT_DIR + '/git_hooks/*.rb'].each do |file|
  require file
end
