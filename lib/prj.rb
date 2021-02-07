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

        @repo = gcli.config['remote.origin.url'].gsub(%r{.*/(.*)\.git}, '\1')
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

      def get_repo_data(viewer)
        if viewer.repository.nil?
          # when no repository is found for the name it might be because it's in an organization
          repo = nil
          viewer.repositories.each do |edge|
            if edge.node.name == @repo
              repo = edge.node
              break
            end
          end
          raise "No repository was found for #{@repo}" if repo.nil?

          repo_id = repo.id
          templates = repo.templates
        else
          repo_id = viewer.repository.id
          templates = viewer.repository.templates
        end

        [repo_id, templates]
      end
    end

    option :template
    option :title
    desc 'issue', 'create GitHub and GitLab issues'
    def issue
      result = Prj::CLIENT.query(Prj::REPO_QUERY, variables: { name: @repo }, context: { token: @token })
      repo_id, templates = get_repo_data(result.data.viewer)

      if (title = options[:title]).nil?
        title = ask 'Issue title:'
      end

      filename = '/tmp/git-prj.scratch.md'
      scratch = File.new(filename, 'w')
      unless (template_name = options[:template]).nil?
        templates.each do |template|
          scratch.write(template.body) if template.name.downcase == template_name.downcase
        end
      end
      scratch.close

      # load the editor to fill the issue body
      system((ENV['EDITOR']).to_s, filename.to_s)
      file = File.open(filename)
      body = file.read
      file.close
      File.delete(filename)

      # create the issue
      variables = {
        input: {
          repositoryId: repo_id,
          title: title,
          body: body
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
