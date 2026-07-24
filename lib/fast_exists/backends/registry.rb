# frozen_string_literal: true

module FastExists
  module Backends
    class Registry
      def initialize
        @backends = {}
        register_default_backends
      end

      def register(name, klass)
        @backends[name.to_sym] = klass
      end

      def fetch(name, options = {})
        backend_name = name.to_sym
        klass = @backends[backend_name]
        raise UnsupportedBackendError, "Backend '#{name}' is not registered" unless klass

        klass.new(options)
      end

      def registered?(name)
        @backends.key?(name.to_sym)
      end

      private

      def register_default_backends
        register(:memory, FastExists::Backends::Memory)
        register(:file, FastExists::Backends::File)
        register(:null, FastExists::Backends::Null)
        register(:redis, FastExists::Backends::Redis)
        register(:redis_bloom, FastExists::Backends::RedisBloom)
      end
    end
  end
end
