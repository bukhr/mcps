# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'dotenv'

module JenkinsMCP
  module Config
    # Configuración del MCP de Jenkins
    class Settings
      MCP_CONFIG_PATH = File.join(Dir.home, '.codeium', 'windsurf', 'mcp_config.json')
      GEMINI_CONFIG_PATH = File.join(Dir.home, '.gemini', 'settings.json')

      DEFAULT_LOG_CONFIG = {
        enable_file_logs: true,
        log_level: 'info'
      }.freeze

      # Carga la configuración de Jenkins
      def self.load_jenkins_config
        config = read_mcp_config
        jenkins_config = config&.dig('jenkins') || {}

        file_base_url = resolve_env_ref(jenkins_config['baseUrl'])
        auth = jenkins_config['auth'] || {}

        base_url = (ENV['JENKINS_BASE_URL'] || file_base_url || '').to_s
        username = (ENV['JENKINS_USERNAME'] || resolve_env_ref(auth['username']) || '').to_s
        api_token = (ENV['JENKINS_API_TOKEN'] || resolve_env_ref(auth['apiToken']) || '').to_s

        raise 'Missing JENKINS_BASE_URL (or jenkins.baseUrl in mcp_config.json)' if base_url.empty?
        raise 'Missing JENKINS_USERNAME (or jenkins.auth.username in mcp_config.json)' if username.empty?
        raise 'Missing JENKINS_API_TOKEN (or jenkins.auth.apiToken in mcp_config.json)' if api_token.empty?

        {
          base_url: base_url.chomp('/'),
          username: username,
          api_token: api_token
        }
      end

      # Carga la configuración de logs
      def self.load_log_config
        Dotenv.load

        begin
          config = read_mcp_config
          return DEFAULT_LOG_CONFIG if config.nil?

          log_config = config.dig('jenkins', 'logs') || {}

          {
            enable_file_logs: if log_config['enableFileLogs'].nil?
                                DEFAULT_LOG_CONFIG[:enable_file_logs]
                              else
                                log_config['enableFileLogs']
                              end,
            log_level: log_config['logLevel'] || DEFAULT_LOG_CONFIG[:log_level],
            log_dir: log_config['logDir']
          }
        rescue StandardError => e
          warn "Failed to load log configuration: #{e.message}"
          DEFAULT_LOG_CONFIG
        end
      end

      # Obtiene el directorio de logs
      def self.log_dir
        File.join(File.dirname(__FILE__), '../../logs')
      end

      # Lee la configuración de MCP
      def self.read_mcp_config
        [MCP_CONFIG_PATH, GEMINI_CONFIG_PATH].each do |path|
          next unless File.exist?(path)

          raw = File.read(path)
          json = JSON.parse(raw)
          return json if json['jenkins']
        end
        nil
      rescue StandardError
        nil
      end

      # Resuelve referencias a variables de entorno
      def self.resolve_env_ref(value)
        if value.is_a?(String) && value.start_with?('env:')
          env_name = value[4..]
          ENV[env_name] || ''
        else
          value
        end
      end
    end
  end
end
