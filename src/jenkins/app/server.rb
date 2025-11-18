# frozen_string_literal: true

require 'mcp'
require 'rackup'
require_relative 'version'
require_relative 'config/settings'
require_relative 'utils/logger'
require_relative 'tools/check_jobs'

module JenkinsMCP
  # MCP Server para Jenkins
  class Server
    # Inicia el MCP Server
    def self.start
      server = MCP::Server.new(
        name: 'jenkins_mcp',
        version: VERSION,
        tools: [Tools::CheckJobs]
      )

      transport = MCP::Server::Transports::StreamableHTTPTransport.new(server)
      server.transport = transport

      server.resources_read_handler do |params|
        [{
          uri: params[:uri],
          mimeType: 'text/plain',
          text: 'Hello from HTTP server resource!'
        }]
      end

      Utils::Logger.app_logger.info('¡MCP server para Jenkins iniciado correctamente!')

      transport = MCP::Server::Transports::StdioTransport.new(server)
      transport.open
    end
  end
end
