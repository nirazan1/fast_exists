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
require_relative "fast_exists/generators/install_generator" if defined?(Rails::Generators::Base)
require_relative "fast_exists/railtie" if defined?(Rails::Railtie)
require_relative "fast_exists/engine" if defined?(Rails::Engine)
require_relative "fast_exists/cli"

module FastExists
  class << self
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

    def stats
      stats_tracker.snapshot
    end

    def reset_stats!
      stats_tracker.reset!
    end
  end
end
