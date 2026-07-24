# frozen_string_literal: true

module FastExists
  module MultiTenant
    module Strategies
      class BaseStrategy
        attr_reader :options

        def initialize(options = {})
          @options = options
        end

        def add(tenant_id, attribute, value)
          raise NotImplementedError, "#{self.class.name}#add is not implemented"
        end

        def contains?(tenant_id, attribute, value)
          raise NotImplementedError, "#{self.class.name}#contains? is not implemented"
        end

        def classify_tenant(tenant_id, record_count)
          :default
        end

        def stats
          { strategy: self.class.name }
        end
      end
    end
  end
end
