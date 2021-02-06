# frozen_string_literal: true

require 'git'
require 'thor'

require_relative 'prj/version'

module Prj
  HOSTS = {
    github: 0,
    gitlab: 1
  }

  # Top-level command for git-prj CLI.
  class CLI < Thor
    def initialize(args = nil, options = nil, config = nil)
      g = Git.open('.')
      @host = Prj::HOSTS[:github]
      @username = g.config['github.username']
      super
    end

    no_commands do
      def host_string(value)
        Prj::HOSTS.key(value)
      end
    end

  desc 'issue', 'create GitHub and GitLab issues'
    def issue
      puts "issue #{host_string(@host)} for #{@username}"
    end

    desc 'pr', 'create a GitHub pull request'
    def pr
      puts 'pr'
    end

    desc 'mr', 'create a GitLab merge request'
    def mr
      puts 'mr'
    end
  end
end
