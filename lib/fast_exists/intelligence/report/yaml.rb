# frozen_string_literal: true

require "yaml"

module FastExists
  module Intelligence
    module Report
      class Yaml
        def self.render(data, comparison: nil)
          payload = data.to_h
          payload[:comparison] = comparison if comparison
          payload.transform_keys(&:to_s).to_yaml
        end
      end
    end
  end
end
