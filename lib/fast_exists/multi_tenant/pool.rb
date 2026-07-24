# frozen_string_literal: true

module FastExists
  module MultiTenant
    class Pool
      attr_reader :name, :expected_elements, :false_positive_rate, :backend

      def initialize(name:, expected_elements:, false_positive_rate: 0.001, backend_type: nil)
        @name = name
        @expected_elements = expected_elements
        @false_positive_rate = false_positive_rate
        @backend_type = backend_type || FastExists.configuration.backend
        @key = FastExists::MultiTenant::KeyLayout.pool_key(name)

        @backend = FastExists.backends.fetch(
          @backend_type,
          namespace: "pool:#{name}",
          expected_elements: expected_elements,
          false_positive_rate: false_positive_rate
        )
      end

      def add(tenant_id, attribute, value)
        composite_key = "#{tenant_id}:#{attribute}:#{value}"
        @backend.add(composite_key)
      end

      def contains?(tenant_id, attribute, value)
        composite_key = "#{tenant_id}:#{attribute}:#{value}"
        @backend.contains?(composite_key)
      end

      def clear
        @backend.clear
      end

      def stats
        @backend.stats.merge(pool_name: @name, pool_key: @key)
      end
    end
  end
end
