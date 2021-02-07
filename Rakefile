# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'

RuboCop::RakeTask.new

task default: %i[spec rubocop]

require_relative 'lib/prj/graphql'

namespace :schema do
  # An offline copy of the schema allows queries to be typed checked statically
  # before even sending a request.
  desc 'Update GitHub GraphQL schema'
  task :update do
    GraphQL::Client.dump_schema(Prj::HTTP, 'schema.json')
  end
end
