# frozen_string_literal: true

require_relative "key_layout"
require_relative "pool"
require_relative "strategies/base_strategy"
require_relative "strategies/global_strategy"
require_relative "strategies/per_tenant_strategy"
require_relative "strategies/shared_strategy"
require_relative "strategies/adaptive_strategy"
require_relative "allocator"
require_relative "recommendation_engine"

module FastExists
  module MultiTenant
    class << self
      def allocator
        @allocator ||= FastExists::MultiTenant::Allocator.new
      end

      def reset!
        @allocator = nil
      end
    end
  end
end
