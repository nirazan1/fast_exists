# frozen_string_literal: true

module FastExists
  module MultiTenancy
    class Resolver
      def self.resolve(namespace_spec, record_or_context = nil)
        case namespace_spec
        when Proc
          namespace_spec.call(record_or_context).to_s
        when Symbol
          if record_or_context && record_or_context.respond_to?(namespace_spec)
            record_or_context.send(namespace_spec).to_s
          else
            namespace_spec.to_s
          end
        when String
          namespace_spec
        else
          "default"
        end
      end
    end
  end
end
