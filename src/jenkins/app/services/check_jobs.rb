# frozen_string_literal: true

module JenkinsMCP
  module Services
    # Servicio para verificar trabajos en Jenkins
    class CheckJobs
      # Crea una respuesta estándar para la verificación de trabajos
      def self.create_job_check_response(job, build_info, log_text)
        {
          status: 'success',
          job: job,
          build: build_info,
          log_full: log_text
        }
      end

      # Extrae el número de build de una URL
      def self.extract_build_number_from_url(url)
        build_number_match = url.chomp('/').match(%r{/(\d+)(?:$|/?)})
        raise "No se pudo extraer el número de build de la URL #{url}" unless build_number_match

        build_number_match[1].to_i
      end

      # Procesa la solicitud de verificación de un trabajo por URL
      def self.process_check_jobs_by_url(client, pipeline_url)
        log_text = client.get_console_text_by_url(pipeline_url)
        build_number = extract_build_number_from_url(pipeline_url)

        build_info = {
          number: build_number,
          url: pipeline_url
        }

        create_job_check_response(pipeline_url, build_info, log_text)
      end

      # Procesa la solicitud de verificación de un trabajo por nombre
      def self.process_check_jobs_by_job(client, job_full_name)
        builds = client.get_builds(job_full_name)

        raise "No builds found for job #{job_full_name}" if builds.empty?

        last_failed = client.find_last_failed(builds)
        raise "No recent failed build found for #{job_full_name}" unless last_failed

        build_number = last_failed['number']
        log_text = client.get_console_text(job_full_name, build_number)

        build_info = {
          number: build_number,
          url: last_failed['url'] || '',
          result: last_failed['result'],
          timestamp: last_failed['timestamp'],
          duration: last_failed['duration']
        }

        create_job_check_response(job_full_name, build_info, log_text)
      end
    end
  end
end
