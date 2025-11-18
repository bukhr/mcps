# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/reporters'
require 'shoulda/context'
require 'mocha/minitest'
require 'webmock/minitest'
require 'pry'
require 'mcp'
require 'logger'

# Agregar la ruta de la aplicación al path
app_path = File.expand_path('../app', __dir__)
$LOAD_PATH.unshift(app_path) unless $LOAD_PATH.include?(app_path)

# Cargar los archivos necesarios
require 'version'
require 'config/settings'
require 'utils/logger'
require 'services/jenkins_client'
require 'services/check_jobs'
require 'tools/check_jobs'

# Configurar formato de salida
Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new(color: true, detailed_skip: false)]

module JenkinsMCP
  class TestCase < Minitest::Test
    extend Shoulda::Context

    def before_setup
      super
      mock_logger = mock('JenkinsMCP::Utils::Logger::DualLogger')
      mock_logger.stubs(:info)
      mock_logger.stubs(:debug)
      mock_logger.stubs(:warn)
      mock_logger.stubs(:error)
      JenkinsMCP::Utils::Logger.stubs(:create_logger).returns(mock_logger)
    end
  end
end
