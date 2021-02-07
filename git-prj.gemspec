# frozen_string_literal: true

require_relative 'lib/prj/version'

Gem::Specification.new do |spec|
  spec.name          = 'git-prj'
  spec.version       = Prj::VERSION
  spec.authors       = ['Geoff Johnson']
  spec.email         = ['geoff.jay@gmail.com']

  spec.summary       = 'Personal Git commands.'
  spec.description   = 'Git subcommands for my personal workflow.'
  spec.homepage      = 'https://github.com/geoffjay/git-prj'
  spec.license       = 'MIT'

  spec.required_ruby_version = Gem::Requirement.new('>= 2.4.0')

  spec.metadata['allowed_push_host'] = 'https://rubygems.org' if spec.respond_to?(:metadata)
  spec.metadata['homepage'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'thor', '~> 1.1'

  spec.add_development_dependency 'bundler', '~> 2.2'
  spec.add_development_dependency 'rake', '~> 13.0'
end
