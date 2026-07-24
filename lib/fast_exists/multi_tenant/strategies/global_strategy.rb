# frozen_string_literal: true

module FastExists
  module MultiTenant
    module Strategies
      class GlobalStrategy < BaseStrategy
        def initialize(options = {})
          super
          @backend = FastExists.backends.fetch(
            FastExists.configuration.backend,
            namespace: "global",
            expected_elements: options[:expected_elements] || FastExists.configuration.expected_elements,
            false_positive_rate: options[:false_positive_rate] || FastExists.configuration.false_positive_rate
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

        def classify_tenant(_tenant_id, _record_count)
          :global
        end

        def stats
          @backend.stats.merge(strategy: :global, key: FastExists::MultiTenant::KeyLayout.global_key)
        end
      end
    end
  end
end
