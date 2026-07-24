# frozen_string_literal: true

require "time"

module FastExists
  module Intelligence
    class DataModel
      attr_accessor :timestamp,
                    :uptime,
                    :environment,
                    :stats,
                    :health,
                    :analysis,
                    :audit,
                    :doctor

      def initialize
        @timestamp = Time.now.utc.iso8601
        @uptime = (FastExists.uptime rescue 0)
        @environment = collect_environment_info
        @stats = FastExists.stats
        @health = {}
        @analysis = {}
        @audit = {}
        @doctor = {}
      end

      def to_h
        {
          timestamp: @timestamp,
          uptime: @uptime,
          environment: @environment,
          stats: @stats,
          health: @health,
          analysis: @analysis,
          audit: @audit,
          doctor: @doctor
        }
      end

      private

      def collect_environment_info
        {
          ruby_version: RUBY_VERSION,
          ruby_platform: RUBY_PLATFORM,
          rails_version: defined?(Rails) && Rails.respond_to?(:version) ? Rails.version : "N/A",
          database_adapter: defined?(ActiveRecord::Base) ? (ActiveRecord::Base.connection_db_config.adapter rescue "sqlite3") : "N/A",
          backend: FastExists.configuration.backend.to_s,
          auto_sync: FastExists.configuration.auto_sync,
          instrumentation: FastExists.configuration.instrumentation,
          metrics: FastExists.configuration.metrics
        }
      end
    end
  end
end
