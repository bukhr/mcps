# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jenkins_mcp/version'

Gem::Specification.new do |spec|
  spec.name          = 'jenkins_mcp'
  spec.version       = JenkinsMCP::VERSION
  spec.authors       = ['BukHR']
  spec.email         = ['dev@buk.cl']

  spec.summary       = 'Jenkins MCP Server para integración con LLMs'
  spec.description   = 'Servidor MCP para interactuar con Jenkins desde modelos de lenguaje'
  spec.license       = 'MIT'

  spec.files         = Dir.glob('{bin,lib}/**/*') + %w[README.md]
  spec.bindir        = 'bin'
  spec.executables   = ['server']
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.2.0'

  spec.add_dependency 'dotenv', '~> 2.8'
  spec.add_dependency 'faraday', '~> 2.7'
  spec.add_dependency 'logger', '~> 1.5'
  spec.add_dependency 'mcp', '~> 0.1'

  spec.add_development_dependency 'minitest', '~> 5.18'
  spec.add_development_dependency 'minitest-reporters', '~> 1.6'
  spec.add_development_dependency 'pry', '~> 0.14'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'webmock', '~> 3.18'
end
