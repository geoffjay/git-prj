# frozen_string_literal: true

require 'git'
require 'pathname'
require 'thor'

require_relative 'prj/graphql'
require_relative 'prj/version'

module Prj
  HOSTS = {
    github: 0,
    gitlab: 1
  }.freeze

  # Top-level command for git-prj CLI.
  class CLI < Thor
    def initialize(args = nil, options = nil, config = nil)
      path = Pathname.new(Dir.pwd)
      begin
        g = Git.open(path)
      rescue ArgumentError
        raise "#{path} doesn't look like a git repository"
      end
      init_host(g)
      init_username(g)
      init_token(g)
      super
    end

    no_commands do
      def host_string(value)
        Prj::HOSTS.key(value)
      end

      def init_host(gcli)
        raise 'The repository needs a remote to be added' unless gcli.config.key?('remote.origin.url')

        url = gcli.config['remote.origin.url']
        if url.include? 'github'
          @host = Prj::HOSTS[:github]
        elsif url.include? 'gitlab'
          @host = Prj::HOSTS[:gitlab]
        end

        @repo = gcli.config['remote.origin.url'].gsub(/.*\/(.*)\.git/, '\1')
      end

      def init_username(gcli)
        unless gcli.config.key?("#{host_string(@host)}.username")
          raise "Could not find git config settings for #{host_string(@host)}.username"
        end
        @username = gcli.config["#{host_string(@host)}.username"]
      end

      def init_token(gcli)
        unless gcli.config.key?("#{host_string(@host)}.token")
          raise "Could not find git config settings for #{host_string(@host)}.token"
        end
        @token = gcli.config["#{host_string(@host)}.token"]
      end
    end

    desc 'issue', 'create GitHub and GitLab issues'
    def issue
      result = Prj::CLIENT.query(Prj::REPO_QUERY, variables: { name: @repo }, context: { token: @token })
      title = ask 'Issue title:'
      filename = '/tmp/git-prj.scratch.md'
      File.new(filename, 'w')
      system("#{ENV['EDITOR']}", "#{filename}")
      file = File.open(filename)
      body = file.read
      file.close
      File.delete(filename)
      variables = {
        input: {
          repositoryId: result.data.viewer.repository.id,
          title: title,
          body: body,
        }
      }
      result = Prj::CLIENT.query(Prj::CREATE_ISSUE_MUTATION, variables: variables, context: { token: @token })

      say "Created #{result.data.create.issue.url}", :green
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
