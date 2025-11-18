# frozen_string_literal: true

require 'test_helper'

class CheckJobsTest < JenkinsMCP::TestCase
  def setup
    @client = Minitest::Mock.new
  end

  context 'extract_build_number_from_url' do
    should 'extraer correctamente el número de build de URLs' do
      # URL con barra final
      url = 'https://jenkins.example.com/job/project/123/'
      assert_equal 123, JenkinsMCP::Services::CheckJobs.extract_build_number_from_url(url)

      # URL sin barra final
      url = 'https://jenkins.example.com/job/project/456'
      assert_equal 456, JenkinsMCP::Services::CheckJobs.extract_build_number_from_url(url)

      # URL sin número de build
      url = 'https://jenkins.example.com/job/project/'
      assert_raises(RuntimeError) do
        JenkinsMCP::Services::CheckJobs.extract_build_number_from_url(url)
      end
    end
  end

  context 'process_check_jobs_by_url' do
    should 'obtener logs por URL del pipeline' do
      pipeline_url = 'https://jenkins.example.com/job/project/789/'
      log_text = 'Este es el log del build'

      @client.expect :get_console_text_by_url, log_text, [pipeline_url]

      response = JenkinsMCP::Services::CheckJobs.process_check_jobs_by_url(@client, pipeline_url)

      assert_equal 'success', response[:status]
      assert_equal pipeline_url, response[:job]
      assert_equal 789, response[:build][:number]
      assert_equal pipeline_url, response[:build][:url]
      assert_equal log_text, response[:log_full]

      @client.verify
    end
  end

  context 'process_check_jobs_by_job' do
    should 'obtener logs por nombre de job cuando hay builds fallidos' do
      job_name = 'example-job'
      build_number = 42
      log_text = 'Este es el log del job'

      builds = [
        { 'number' => build_number, 'result' => 'FAILURE', 'url' => 'https://jenkins.example.com/job/example-job/42/',
          'timestamp' => 1_605_000_000_000, 'duration' => 60_000 },
        { 'number' => 41, 'result' => 'SUCCESS', 'url' => 'https://jenkins.example.com/job/example-job/41/' }
      ]

      failed_build = builds.first

      @client.expect :get_builds, builds, [job_name]
      @client.expect :find_last_failed, failed_build, [builds]
      @client.expect :get_console_text, log_text, [job_name, build_number]

      response = JenkinsMCP::Services::CheckJobs.process_check_jobs_by_job(@client, job_name)

      assert_equal 'success', response[:status]
      assert_equal job_name, response[:job]
      assert_equal build_number, response[:build][:number]
      assert_equal 'https://jenkins.example.com/job/example-job/42/', response[:build][:url]
      assert_equal 'FAILURE', response[:build][:result]
      assert_equal 1_605_000_000_000, response[:build][:timestamp]
      assert_equal 60_000, response[:build][:duration]
      assert_equal log_text, response[:log_full]

      @client.verify
    end

    should 'lanzar un error cuando no hay builds' do
      job_name = 'empty-job'

      @client.expect :get_builds, [], [job_name]

      error = assert_raises(RuntimeError) do
        JenkinsMCP::Services::CheckJobs.process_check_jobs_by_job(@client, job_name)
      end

      assert_equal "No builds found for job #{job_name}", error.message

      @client.verify
    end

    should 'lanzar un error cuando no hay builds fallidos' do
      job_name = 'successful-job'
      builds = [
        { 'number' => 2, 'result' => 'SUCCESS' },
        { 'number' => 1, 'result' => 'SUCCESS' }
      ]

      @client.expect :get_builds, builds, [job_name]
      @client.expect :find_last_failed, nil, [builds]

      error = assert_raises(RuntimeError) do
        JenkinsMCP::Services::CheckJobs.process_check_jobs_by_job(@client, job_name)
      end

      assert_equal "No recent failed build found for #{job_name}", error.message

      @client.verify
    end
  end
end
