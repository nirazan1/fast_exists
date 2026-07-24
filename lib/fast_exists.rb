# frozen_string_literal: true

require_relative "fast_exists/version"
require_relative "fast_exists/errors"
require_relative "fast_exists/configuration"
require_relative "fast_exists/bit_array"
require_relative "fast_exists/bloom/filter"
require_relative "fast_exists/bloom/scalable"
require_relative "fast_exists/bloom/counting"
require_relative "fast_exists/probabilistic/cuckoo"
require_relative "fast_exists/probabilistic/hyper_log_log"
require_relative "fast_exists/probabilistic/count_min_sketch"
require_relative "fast_exists/backends/base"
require_relative "fast_exists/backends/memory"
require_relative "fast_exists/backends/file"
require_relative "fast_exists/backends/null"
require_relative "fast_exists/backends/redis"
require_relative "fast_exists/backends/redis_bloom"
require_relative "fast_exists/backends/registry"
require_relative "fast_exists/statistics/tracker"
require_relative "fast_exists/instrumentation/event_subscriber"
require_relative "fast_exists/instrumentation/prometheus"
require_relative "fast_exists/instrumentation/open_telemetry"
require_relative "fast_exists/multi_tenancy/resolver"
require_relative "fast_exists/optimizer/ai_advisor"
require_relative "fast_exists/active_record/model_methods"
require_relative "fast_exists/active_record/hooks"
require_relative "fast_exists/active_record/extension"

# Performance Intelligence Suite
require_relative "fast_exists/intelligence/data_model"
require_relative "fast_exists/intelligence/stats"
require_relative "fast_exists/intelligence/health"
require_relative "fast_exists/intelligence/analyzer"
require_relative "fast_exists/intelligence/auditor"
require_relative "fast_exists/intelligence/doctor"
require_relative "fast_exists/intelligence/report/json"
require_relative "fast_exists/intelligence/report/yaml"
require_relative "fast_exists/intelligence/report/markdown"
require_relative "fast_exists/intelligence/report/csv"
require_relative "fast_exists/intelligence/report/pdf"
require_relative "fast_exists/intelligence/report/html"
require_relative "fast_exists/intelligence/report/console"
require_relative "fast_exists/intelligence/report/builder"

require_relative "fast_exists/generators/install_generator" if defined?(Rails::Generators::Base)
require_relative "fast_exists/railtie" if defined?(Rails::Railtie)
require_relative "fast_exists/engine" if defined?(Rails::Engine)
require_relative "fast_exists/cli"

module FastExists
  @start_time = Time.now

  class << self
    attr_reader :start_time

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def backends
      @backends ||= FastExists::Backends::Registry.new
    end

    def register_backend(name, klass)
      backends.register(name, klass)
    end

    def stats_tracker
      @stats_tracker ||= FastExists::Statistics::Tracker.new
    end

    def stats(format: nil, **options)
      if format
        FastExists::Intelligence::Stats.render(format: format)
      else
        stats_tracker.snapshot
      end
    end

    def reset_stats!
      stats_tracker.reset!
    end

    def uptime
      (Time.now - @start_time).round
    end

    # Performance Intelligence Suite Public API

    def health!
      FastExists::Intelligence::Health.check
    end

    def analyze!(target = nil, attribute = nil, models: nil, format: nil, output: nil)
      res = FastExists::Intelligence::Analyzer.analyze(target, attribute, models: models)
      if format || output
        fmt = format || :json
        case fmt.to_sym
        when :json then JSON.pretty_generate(res)
        when :yaml then res.transform_keys(&:to_s).to_yaml
        else res
        end
      else
        res
      end
    end

    def audit!
      FastExists::Intelligence::Auditor.audit
    end

    def doctor!(format: :console)
      FastExists::Intelligence::Doctor.diagnose(format: format)
    end

    def report!(format: :html, output: nil, include: nil, compare: nil)
      FastExists::Intelligence::Report::Builder.build(
        format: format,
        output: output,
        include: include,
        compare: compare
      )
    end
  end
end
