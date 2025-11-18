# frozen_string_literal: true

require 'faraday'
require 'faraday/net_http'
require 'json'
require 'uri'
require 'cgi'
require_relative '../utils/logger'

module JenkinsMCP
  module Services
    # Cliente para interactuar con la API de Jenkins
    class JenkinsClient
      API_ENDPOINTS = {
        console_text: 'consoleText',
        api_json: 'api/json'
      }.freeze

      API_PARAMS = {
        build_tree: 'builds[number,result,building,timestamp,duration,url]'
      }.freeze

      URL_PATTERNS = {
        blue_ocean: %r{^/blue/organizations/jenkins/([^/]+)/detail/([^/]+)/(\d+)(?:/.*)?$},
        pr_number: /^PR-\d+$/i
      }.freeze

      # Crea una instancia del cliente Jenkins
      def initialize(jenkins_config)
        @client = Faraday.new(
          url: jenkins_config[:base_url],
          headers: { 'Content-Type': 'application/json' }
        ) do |faraday|
          # Usar autenticación básica directamente con el constructor
          faraday.request(:authorization, :basic, jenkins_config[:username], jenkins_config[:api_token])
          faraday.adapter :net_http
        end
        @logger = Utils::Logger.create_logger('jenkins_mcp', 'jenkins-client')
      end

      # Construye la ruta para un trabajo de Jenkins
      def build_job_path(job_full_name)
        parts = job_full_name.split('/').reject(&:empty?)
        parts.map { |p| "job/#{CGI.escape(p).gsub('+', '%20')}" }.join('/')
      end

      # Obtiene los builds de un trabajo
      def get_builds(job_full_name)
        path = build_job_path(job_full_name)
        url = "/#{path}/#{API_ENDPOINTS[:api_json]}"
        params = { tree: API_PARAMS[:build_tree] }

        begin
          response = @client.get(url, params)
          data = JSON.parse(response.body)
          data['builds'] || []
        rescue StandardError => e
          @logger.error("Error al obtener builds para #{job_full_name}: #{e.message}")
          []
        end
      end

      # Obtiene el texto de la consola de un build específico
      def get_console_text(job_full_name, build_number)
        path = build_job_path(job_full_name)
        url = "/#{path}/#{build_number}/#{API_ENDPOINTS[:console_text]}"
        fetch_console_text(url)
      end

      # Obtiene el texto de la consola usando la URL del build
      def get_console_text_by_url(absolute_build_url)
        clean = absolute_build_url.chomp('/')
        classic_base = convert_to_classic_build_url(clean) || clean
        url = "#{classic_base}/#{API_ENDPOINTS[:console_text]}"
        fetch_console_text(url)
      end

      # Encuentra el último build fallido en una lista de builds
      def find_last_failed(builds)
        builds.find { |build| build && build['result'] == 'FAILURE' }
      end

      private

        # Método genérico para obtener texto de la consola
        def fetch_console_text(url)
          response = @client.get(url)
          response.body.to_s
        rescue StandardError => e
          @logger.error("Error al obtener texto de consola desde #{url}: #{e.message}")
          ''
        end

        # Convierte una URL de Jenkins Blue Ocean a su equivalente en la interfaz clásica
        def convert_to_classic_build_url(blue_url)
          uri = URI.parse(blue_url)
          path = uri.path.chomp('/')
          path_match = path.match(URL_PATTERNS[:blue_ocean])

          return nil unless path_match

          job_name_raw, branch_or_pr_raw, build_number = path_match[1, 3]
          job_name = URI.decode_www_form_component(job_name_raw)
          branch_or_pr = URI.decode_www_form_component(branch_or_pr_raw)

          is_pr = URL_PATTERNS[:pr_number].match?(branch_or_pr)
          encoded_job = URI.encode_www_form_component(job_name)
          encoded_branch = URI.encode_www_form_component(branch_or_pr)

          base = "#{uri.scheme}://#{uri.host}:#{uri.port}/job/#{encoded_job}"
          if is_pr
            "#{base}/view/change-requests/job/#{encoded_branch}/#{build_number}"
          else
            "#{base}/job/#{encoded_branch}/#{build_number}"
          end
        rescue StandardError => e
          @logger.error("Error al convertir URL de Blue Ocean: #{e.message}")
          nil
        end
    end
  end
end
