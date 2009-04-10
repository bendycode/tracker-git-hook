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
        commit.message.scan(/\[Story([0-9]+)\s*(.*?)\]\s*(.*)$/) do |match|
          story_number = match[0]
          params = match[1]
          comment = match[2]
          @changes << parse_change(commit, story_number, params, comment)
        end
      end
      self
    end

    def send_changes
      @changes.each do |story_hash|
        story_num = story_hash[:story_number]
        commit = story_hash[:commit]
        comment = story_hash[:comment]

        Configuration.login(commit.committer.email)
        project_number = Configuration[:project_number]
        user_token = Configuration[:api_token]
        project = Tracker.new(project_number, user_token)
        puts "updating Story#{story_num}"

        if story_hash['state']
          # story = project.find_story(story_num)
          # puts "found story: #{story.inspect}\n\n\n\n"
          # story[:current_state] = story_hash['state']
          project.update_state(story_num.to_s, story_hash['state'])
        end
        message = build_message(commit, @ref, comment)
        project.add_comment(story_num, message)
      end
    end

    protected

    def build_message(commit, ref, comment)
      message = comment
      message << "\n\ncommit #{commit.id} on #{ref}\n"
    end

    def parse_change(commit, story_number, params, comment)
      change = {:story_number => story_number.to_i, :commit => commit, :comment => comment}

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
