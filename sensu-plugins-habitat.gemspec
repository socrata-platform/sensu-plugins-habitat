# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'date'
require 'sensu_plugins_habitat/version'

Gem::Specification.new do |s|
  s.authors = ['Tyler Technologies']
  s.date = Date.today.to_s
  s.description = 'This plugin monitors services under a Habitat supervisor'
  s.email = '<sysadmin@socrata.com>'
  s.executables = Dir.glob('bin/**/*.rb').map { |file| File.basename(file) }
  s.files = [
    Dir.glob('{bin,lib}/**/*'),
    'LICENSE',
    'README.md',
    'CHANGELOG.md'
  ]
  s.homepage = 'https://github.com/socrata-platform/sensu-plugins-habitat'
  s.license = 'MIT'
  s.metadata = { 'maintainer' => 'tyler-technologies',
                 'development_status' => 'active',
                 'production_status' => 'unstable - testing recommended',
                 'release_draft' => 'false',
                 'release_prerelease' => 'false' }
  s.name = 'sensu-plugins-habitat'
  s.platform = Gem::Platform::RUBY
  s.post_install_message = 'You can use the embedded Ruby by setting ' \
                           'EMBEDDED_RUBY=true in /etc/default/sensu'
  s.require_paths = %w[lib]
  s.required_ruby_version = '>= 2.3.0'
  s.summary = 'Sensu plugins for monitoring Habitat services'
  s.test_files = s.files.grep(%r{^(test|spec|features)/})
  s.version = SensuPluginsHabitat::Version::VER_STRING

  s.add_runtime_dependency 'sensu-plugin', '>= 1.2', '< 4.0'

  s.add_development_dependency 'bundler', '~> 2.0'
  s.add_development_dependency 'github-markup', '~> 3.0'
  s.add_development_dependency 'pry', '~> 0.11'
  s.add_development_dependency 'rake', '~> 12.3'
  s.add_development_dependency 'redcarpet', '~> 3.4'
  s.add_development_dependency 'rspec', '~> 3.8'
  s.add_development_dependency 'rubocop', '~> 0.63'
  s.add_development_dependency 'simplecov', '~> 0.16'
  s.add_development_dependency 'simplecov-console', '~> 0.4'
  s.add_development_dependency 'yard', '~> 0.9'
end
