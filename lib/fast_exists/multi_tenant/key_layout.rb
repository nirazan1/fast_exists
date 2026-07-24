# frozen_string_literal: true

module FastExists
  module MultiTenant
    class KeyLayout
      def self.global_key(prefix = FastExists.configuration.key_prefix)
        "#{prefix}:global"
      end

      def self.pool_key(pool_name, prefix = FastExists.configuration.key_prefix)
        "#{prefix}:pool:#{pool_name}"
      end

      def self.tenant_key(tenant_id, prefix = FastExists.configuration.key_prefix)
        "#{prefix}:tenant:#{tenant_id}"
      end
    end
  end
end
