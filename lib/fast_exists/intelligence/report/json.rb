# frozen_string_literal: true

require "json"

module FastExists
  module Intelligence
    module Report
      class Json
        def self.render(data, comparison: nil)
          payload = data.to_h
          payload[:comparison] = comparison if comparison
          JSON.pretty_generate(payload)
        end
      end
    end
  end
end
