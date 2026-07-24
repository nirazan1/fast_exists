# frozen_string_literal: true

module FastExists
  class Configuration
    attr_accessor :backend,
                  :false_positive_rate,
                  :expected_elements,
                  :auto_sync,
                  :instrumentation,
                  :metrics,
                  :redis,
                  :file_path,
                  :logger

    def initialize
      @backend = :memory
      @false_positive_rate = 0.001
      @expected_elements = 1_000_000
      @auto_sync = true
      @instrumentation = true
      @metrics = true
      @redis = nil
      @file_path = nil
      @logger = defined?(Rails) && Rails.respond_to?(:logger) ? Rails.logger : nil
    end

    def reset!
      initialize
    end
  end
end
