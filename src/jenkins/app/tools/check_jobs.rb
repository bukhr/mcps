# frozen_string_literal: true

require_relative '../utils/logger'
require_relative '../services/jenkins_client'
require_relative '../services/check_jobs'
require_relative '../config/settings'

module JenkinsMCP
  module Tools
    # Herramienta para obtener los logs de builds fallidos en Jenkins
    class CheckJobs < MCP::Tool
      description 'Get the last failed build for a Jenkins job and return the full log'
      input_schema(
        properties: {
          job_full_name: {
            type: 'string',
            description: 'Full Jenkins job name, e.g., "Folder/Sub/Job"'
          },
          pipeline_url: {
            type: 'string',
            description: 'Absolute Jenkins build URL, e.g., "https://jenkins.example.com/job/foo/15/"'
          }
        }
      )

      class << self
        # Método de llamada para la herramienta
        def call(job_full_name: nil, pipeline_url: nil)
          tool_logger = Utils::Logger.create_logger('jenkins_tool', 'check-jobs')

          if !pipeline_url && !job_full_name
            return MCP::Tool::Response.new([
                                             {
                                               type: 'text',
                                               text: 'Either pipeline_url or job_full_name is required'
                                             }
                                           ])
          end

          jenkins_config = Config::Settings.load_jenkins_config
          client = Services::JenkinsClient.new(jenkins_config)

          if pipeline_url
            tool_logger.info("Fetching build by URL: #{pipeline_url}")
            payload = Services::CheckJobs.process_check_jobs_by_url(client, pipeline_url)
          else
            tool_logger.info("Fetching builds for job: #{job_full_name}")
            payload = Services::CheckJobs.process_check_jobs_by_job(client, job_full_name)
          end

          MCP::Tool::Response.new([
                                    {
                                      type: 'text',
                                      text: JSON.pretty_generate(payload)
                                    }
                                  ])
        rescue StandardError => e
          error_message = e.message
          tool_logger.error("Error processing request: #{error_message}")

          MCP::Tool::Response.new([
                                    {
                                      type: 'text',
                                      text: "Error while checking jobs: #{error_message}"
                                    }
                                  ])
        end
      end
    end
  end
end
