# frozen_string_literal: true

module FastExists
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class BackendError < Error; end
  class UnsupportedBackendError < Error; end
  class CapacityExceededError < Error; end
  class InvalidArgumentError < Error; end
end
