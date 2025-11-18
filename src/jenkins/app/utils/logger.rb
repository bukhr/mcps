# frozen_string_literal: true

require 'logger'
require 'fileutils'
require_relative '../config/settings'

module JenkinsMCP
  module Utils
    # Utilidades para logging
    class Logger
      # Logger personalizado que escribe en consola y archivo
      class DualLogger < ::Logger
        def initialize(console_io, file_io = nil)
          super(console_io)
          @file_logger = ::Logger.new(file_io) if file_io
        end

        def add(severity, message = nil, progname = nil, &block)
          super(severity, message, progname, &block)
          @file_logger&.add(severity, message, progname, &block)
          true
        end
      end

      # Crea un logger con la configuración simplificada
      def self.create_logger(service, _filename = nil)
        log_config = Config::Settings.load_log_config
        log_dir = log_config[:log_dir] || Config::Settings.log_dir

        # Asegurar que el directorio de logs exista
        FileUtils.mkdir_p(log_dir) if log_config[:enable_file_logs] && !Dir.exist?(log_dir)

        # Crear formatter personalizado
        formatter = proc do |severity, datetime, _progname, msg|
          date_format = datetime.strftime('%Y-%m-%d %H:%M:%S')
          "[#{date_format}] #{severity} #{service}: #{msg}\n"
        end

        # Crear logger para consola y archivo
        logger = if log_config[:enable_file_logs]
                   # Un solo archivo de log para todo
                   log_file = File.join(log_dir, 'jenkins_mcp.log')
                   DualLogger.new($stdout, log_file)
                 else
                   DualLogger.new($stdout)
                 end

        # Configurar logger
        logger.level = log_level_from_string(log_config[:log_level])
        logger.formatter = formatter

        logger
      end

      def self.app_logger
        @app_logger ||= create_logger('jenkins_mcp')
      end

      # Convertir nivel de log de string a constante de Logger
      def self.log_level_from_string(level_string)
        case level_string&.downcase
        when 'debug' then ::Logger::DEBUG
        when 'info' then ::Logger::INFO
        when 'warn' then ::Logger::WARN
        when 'error' then ::Logger::ERROR
        when 'fatal' then ::Logger::FATAL
        else ::Logger::INFO
        end
      end
    end
  end
end
