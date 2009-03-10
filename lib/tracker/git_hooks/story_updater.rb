require 'fileutils'

module Tracker::GitHooks
  class StoryUpdater < Base
    AUTHORIZED_KEYS = [ 'state' ]

    def initialize(old_rev, new_rev, ref = nil)
      super()
      @ref = ref

      @commits = Grit::Commit.find_all(@repo, "#{old_rev}..#{new_rev}",
        :first_parent => true, :no_merges => true)

      @message = ''
      @changes = []
    end

    def parse
      @commits.each do |commit|
        commit.message.scan(/\[Story([0-9]+)\s*(.*?)\]/) do |match|
          story_number = match[0]
          params = match[1]
          @changes << parse_change(commit, story_number, params)
        end
      end
      self
    end

    def send_changes
      @changes.each do |story_hash|
        story_num = story_hash[:story_number]
        commit = story_hash[:commit]

        Configuration.login(commit.commiter.email)
        project = Tracker.new(PROJECT_NUMBER, USER_TOKEN)

        puts "updating Story#{story_num}"

        if story_hash['state']
          # story = project.find_story(story_num)
          # puts "found story: #{story.inspect}\n\n\n\n"
          # story[:current_state] = story_hash['state']
          project.update_state(story_num.to_s, story_hash['state'])
        end
        project.add_comment(story_num, build_message(commit, ref))
      end
    end

    protected

    def build_message(commit, ref)
      message = commit.message
      message << "\n\ncommit #{commit.id} on #{ref}\n"
    end

    def parse_change(commit, story_number, params)
      change = {:story_number => story_number.to_i, :commit => commit}

      unless params.nil?
        params.scan(/(\w+):(\w+|'.*?')/) do |key, value|
          if AUTHORIZED_KEYS.include?(key)
            change[key] = value
          end
        end
      end
      change
    end
  end
end
