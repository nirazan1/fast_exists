# frozen_string_literal: true

module FastExists
  module MultiTenant
    module Strategies
      class PerTenantStrategy < BaseStrategy
        def initialize(options = {})
          super
          @tenant_backends = {}
          @mutex = Mutex.new
        end

        def add(tenant_id, attribute, value)
          backend = tenant_backend_for(tenant_id)
          composite_key = "#{attribute}:#{value}"
          backend.add(composite_key)
        end

        def contains?(tenant_id, attribute, value)
          backend = tenant_backend_for(tenant_id)
          composite_key = "#{attribute}:#{value}"
          backend.contains?(composite_key)
        end

        def classify_tenant(_tenant_id, _record_count)
          :per_tenant
        end

        def stats
          @mutex.synchronize do
            {
              strategy: :per_tenant,
              active_tenant_filters: @tenant_backends.size,
              tenant_keys: @tenant_backends.keys.map { |t| FastExists::MultiTenant::KeyLayout.tenant_key(t) }
            }
          end
        end

        private

        def tenant_backend_for(tenant_id)
          @mutex.synchronize do
            @tenant_backends[tenant_id.to_s] ||= FastExists.backends.fetch(
              FastExists.configuration.backend,
              namespace: "tenant:#{tenant_id}",
              expected_elements: options[:expected_elements] || FastExists.configuration.expected_elements,
              false_positive_rate: options[:false_positive_rate] || FastExists.configuration.false_positive_rate
            )
          end
        end
      end
    end
  end
end
