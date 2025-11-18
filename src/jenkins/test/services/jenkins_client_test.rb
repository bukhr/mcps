# frozen_string_literal: true

require 'test_helper'
require 'base64'

class JenkinsClientTest < JenkinsMCP::TestCase
  def setup
    @config = {
      base_url: 'https://jenkins.example.com',
      username: 'usuario',
      api_token: 'token123'
    }
    @client = JenkinsMCP::Services::JenkinsClient.new(@config)
  end

  context 'build_job_path' do
    should 'construir correctamente rutas de jobs' do
      assert_equal 'job/folder/job/job', @client.build_job_path('folder/job')
      assert_equal 'job/folder1/job/folder2/job/job', @client.build_job_path('folder1/folder2/job')
      assert_equal 'job/folder/job/job%20name', @client.build_job_path('folder/job name')
    end
  end

  context 'get_builds' do
    should 'obtener la lista de builds de un job' do
      job_name = 'test-job'
      api_url = 'https://jenkins.example.com/job/test-job/api/json?tree=builds%5Bnumber%2Cresult%2Cbuilding%2Ctimestamp%2Cduration%2Curl%5D'

      response_body = {
        builds: [
          { number: 1, result: 'SUCCESS', url: 'https://jenkins.example.com/job/test-job/1/' },
          { number: 2, result: 'FAILURE', url: 'https://jenkins.example.com/job/test-job/2/' }
        ]
      }.to_json

      auth_header = "Basic #{Base64.strict_encode64('usuario:token123')}"

      stub_request(:get, api_url)
        .with(headers: { 'Authorization' => auth_header })
        .to_return(status: 200, body: response_body, headers: { 'Content-Type' => 'application/json' })

      builds = @client.get_builds(job_name)
      assert_equal 2, builds.length
      assert_equal 1, builds[0]['number']
      assert_equal 'SUCCESS', builds[0]['result']
      assert_equal 2, builds[1]['number']
      assert_equal 'FAILURE', builds[1]['result']
    end
  end

  context 'find_last_failed' do
    should 'encontrar el último build fallido' do
      builds = [
        { 'number' => 3, 'result' => 'SUCCESS' },
        { 'number' => 2, 'result' => 'FAILURE' },
        { 'number' => 1, 'result' => 'SUCCESS' }
      ]

      failed_build = @client.find_last_failed(builds)
      assert_equal 2, failed_build['number']
      assert_equal 'FAILURE', failed_build['result']

      # Probar con builds todos exitosos
      successful_builds = [
        { 'number' => 2, 'result' => 'SUCCESS' },
        { 'number' => 1, 'result' => 'SUCCESS' }
      ]

      assert_nil @client.find_last_failed(successful_builds)
    end
  end

  context 'get_console_text' do
    should 'obtener el texto de la consola por nombre de job y número de build' do
      job_name = 'test-job'
      build_number = 123
      console_output = "Build iniciado\nCompilando\nTests ejecutados\nBuild finalizado"
      console_url = 'https://jenkins.example.com/job/test-job/123/consoleText'
      auth_header = "Basic #{Base64.strict_encode64('usuario:token123')}"

      stub_request(:get, console_url)
        .with(headers: { 'Authorization' => auth_header })
        .to_return(status: 200, body: console_output)

      result = @client.get_console_text(job_name, build_number)
      assert_equal console_output, result
    end

    should 'manejar errores al obtener el texto de la consola' do
      job_name = 'error-job'
      build_number = 456
      console_url = 'https://jenkins.example.com/job/error-job/456/consoleText'
      auth_header = "Basic #{Base64.strict_encode64('usuario:token123')}"

      stub_request(:get, console_url)
        .with(headers: { 'Authorization' => auth_header })
        .to_return(status: 404)

      result = @client.get_console_text(job_name, build_number)
      assert_equal '', result
    end
  end

  context 'get_console_text_by_url' do
    should 'obtener el texto de la consola por URL del build' do
      build_url = 'https://jenkins.example.com/job/test-job/789/'
      console_url = 'https://jenkins.example.com/job/test-job/789/consoleText'
      console_output = "Build iniciado\nCompilando\nTests ejecutados\nBuild finalizado"
      auth_header = "Basic #{Base64.strict_encode64('usuario:token123')}"

      stub_request(:get, console_url)
        .with(headers: { 'Authorization' => auth_header })
        .to_return(status: 200, body: console_output)

      result = @client.get_console_text_by_url(build_url)
      assert_equal console_output, result
    end

    should 'convertir URLs de Blue Ocean a interfaz clásica' do
      blue_ocean_url = 'https://jenkins.example.com/blue/organizations/jenkins/my-project/detail/master/42/'
      classic_url = 'https://jenkins.example.com/job/my-project/job/master/42/consoleText'
      console_output = 'Ejecutando en branch master'
      auth_header = "Basic #{Base64.strict_encode64('usuario:token123')}"

      # Hacemos que el cliente devuelva una URL clásica y luego acceda al contenido
      stub_request(:get, classic_url)
        .with(headers: { 'Authorization' => auth_header })
        .to_return(status: 200, body: console_output)

      result = @client.get_console_text_by_url(blue_ocean_url)
      assert_equal console_output, result
    end

    should 'manejar errores al convertir URL de Blue Ocean' do
      invalid_url = 'https://jenkins.example.com/invalid/path/'
      console_url = 'https://jenkins.example.com/invalid/path/consoleText'
      auth_header = "Basic #{Base64.strict_encode64('usuario:token123')}"

      stub_request(:get, console_url)
        .with(headers: { 'Authorization' => auth_header })
        .to_return(status: 404)

      result = @client.get_console_text_by_url(invalid_url)
      assert_equal '', result
    end
  end
end
