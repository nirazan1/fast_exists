# frozen_string_literal: true

FastExists.configure do |config|
  # Default backend storage (:memory, :redis, :redis_bloom, :file, :null)
  config.backend = :memory

  # Target false positive rate (0.1% default)
  config.false_positive_rate = 0.001

  # Initial expected elements per bloom filter
  config.expected_elements = 1_000_000

  # Automatic synchronization on record commit
  config.auto_sync = true

  # ActiveSupport::Notifications instrumentation
  config.instrumentation = true

  # Enable runtime metrics collection
  config.metrics = true

  # Optional Redis configuration
  # config.redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
end
