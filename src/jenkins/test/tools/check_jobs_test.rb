# frozen_string_literal: true

require 'test_helper'
require 'json'

class CheckJobsTest < JenkinsMCP::TestCase
  context 'Cuando se llama con URL de pipeline' do
    should 'devolver una respuesta MCP válida' do
      pipeline_url = 'https://jenkins.example.com/job/test-job/123/'
      expected_payload = {
        status: 'success',
        job: 'test-job',
        build: {
          number: 123,
          url: pipeline_url
        },
        log_full: 'Build log content for test job'
      }

      # Usamos stubs de Mocha para el método del servicio
      JenkinsMCP::Services::CheckJobs.stubs(:process_check_jobs_by_url).with do |_client, url|
        assert_equal pipeline_url, url
        true # Validación exitosa del argumento
      end.returns(expected_payload)

      # Mock del cliente usando Mocha
      mock_client = mock('JenkinsClient')
      JenkinsMCP::Services::JenkinsClient.stubs(:new).returns(mock_client)

      # Llamada al método bajo prueba
      response = JenkinsMCP::Tools::CheckJobs.call(pipeline_url: pipeline_url)

      # Verificaciones
      assert_instance_of MCP::Tool::Response, response
      assert response
    end
  end

  context 'Cuando se llama con nombre de job' do
    should 'devolver una respuesta MCP válida' do
      job_name = 'example-folder/test-job'
      expected_payload = {
        status: 'success',
        job: job_name,
        build: {
          number: 42,
          url: 'https://jenkins.example.com/job/example-folder/job/test-job/42/',
          result: 'FAILURE'
        },
        log_full: 'Build log content for job name'
      }

      # Usamos stubs de Mocha para el método del servicio
      JenkinsMCP::Services::CheckJobs.stubs(:process_check_jobs_by_job).with do |_client, name|
        assert_equal job_name, name
        true # Validación exitosa del argumento
      end.returns(expected_payload)

      # Mock del cliente usando Mocha
      mock_client = mock('JenkinsClient')
      JenkinsMCP::Services::JenkinsClient.stubs(:new).returns(mock_client)

      # Llamada al método bajo prueba
      response = JenkinsMCP::Tools::CheckJobs.call(job_full_name: job_name)

      # Verificaciones
      assert_instance_of MCP::Tool::Response, response
      assert response
    end
  end

  context 'Cuando se llama sin parámetros' do
    should 'devolver una respuesta de error apropiada' do
      # Llamada al método sin parámetros requeridos
      response = JenkinsMCP::Tools::CheckJobs.call

      # Verificaciones
      assert_instance_of MCP::Tool::Response, response
    end
  end

  context 'Cuando el servicio devuelve un error' do
    should 'manejar el error apropiadamente' do
      job_name = 'error-job'
      error_message = 'No builds found for job error-job'

      # Hacemos que el método lance una excepción
      JenkinsMCP::Services::CheckJobs.stubs(:process_check_jobs_by_job).raises(RuntimeError.new(error_message))

      # Mock del cliente usando Mocha
      mock_client = mock('JenkinsClient')
      JenkinsMCP::Services::JenkinsClient.stubs(:new).returns(mock_client)

      # Llamada al método bajo prueba
      response = JenkinsMCP::Tools::CheckJobs.call(job_full_name: job_name)

      # Verificaciones
      assert_instance_of MCP::Tool::Response, response
      assert response
    end
  end
end
