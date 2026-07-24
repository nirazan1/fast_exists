# frozen_string_literal: true

module FastExists
  module MultiTenant
    class Allocator
      attr_reader :strategy

      def initialize(strategy_type = FastExists.configuration.tenant_strategy, options = {})
        @strategy_type = strategy_type.to_sym
        @strategy = build_strategy(@strategy_type, options)
      end

      def add(tenant_id, attribute, value)
        @strategy.add(tenant_id, attribute, value)
      end

      def contains?(tenant_id, attribute, value)
        @strategy.contains?(tenant_id, attribute, value)
      end

      def stats
        @strategy.stats.merge(strategy_type: @strategy_type)
      end

      private

      def build_strategy(type, options)
        case type
        when :global
          FastExists::MultiTenant::Strategies::GlobalStrategy.new(options)
        when :per_tenant
          FastExists::MultiTenant::Strategies::PerTenantStrategy.new(options)
        when :shared
          FastExists::MultiTenant::Strategies::SharedStrategy.new(options)
        when :adaptive
          FastExists::MultiTenant::Strategies::AdaptiveStrategy.new(options)
        else
          raise UnsupportedBackendError, "Unknown tenant strategy: #{type}"
        end
      end
    end
  end
end
