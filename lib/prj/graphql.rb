# frozen_string_literal: true

require 'graphql/client'
require 'graphql/client/http'

# GraphQL client and queries.
module Prj
  HTTP = GraphQL::Client::HTTP.new('https://api.github.com/graphql') do
    def headers(context)
      raise 'Missing GitHub access token' unless context[:token] || ENV['GITHUB_API_TOKEN']

      token = context[:token] || ENV['GITHUB_API_TOKEN']
      auth = "Bearer #{token}"

      {
        "User-Agent": 'git-prj',
        Authorization: auth,
        "X-Date": Time.new
      }
    end
  end

  # Fetch latest schema on init, this will make a network request
  # TODO: bail if file doesn't exist?
  path = Pathname.new(Dir.pwd).join('schema.json').to_s
  raise 'The schema.json file does not exist' unless File.exist?(path)

  SCHEMA = GraphQL::Client.load_schema(path)
  CLIENT = GraphQL::Client.new(schema: SCHEMA, execute: HTTP)

  REPO_QUERY = CLIENT.parse <<-'GQL'
    query ($name: String!) {
      viewer {
        repository(name: $name) {
          id
          templates:issueTemplates {
            name
            body
          }
        }
        repositories:repositoriesContributedTo(first: 20) {
          edges {
            node {
              id
              templates:issueTemplates {
                name
                body
              }
            }
          }
        }
      }
    }
  GQL

  CREATE_ISSUE_MUTATION = CLIENT.parse <<-'GQL'
    mutation ($input: CreateIssueInput!) {
      create:createIssue(input: $input) {
        issue {
          url
        }
      }
    }
  GQL
end
