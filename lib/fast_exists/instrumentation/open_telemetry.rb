# frozen_string_literal: true

module FastExists
  module Instrumentation
    class OpenTelemetry
      def self.trace(name, attributes = {})
        if defined?(::OpenTelemetry::Trace)
          tracer = ::OpenTelemetry.tracer_provider.tracer("fast_exists", FastExists::VERSION)
          tracer.in_span("fast_exists.#{name}", attributes: attributes) do |span|
            yield span if block_given?
          end
        elsif block_given?
          yield nil
        end
      end
    end
  end
end
