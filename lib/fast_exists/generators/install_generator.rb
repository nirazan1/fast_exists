# frozen_string_literal: true

if defined?(Rails::Generators::Base)
  module FastExists
    module Generators
      class InstallGenerator < Rails::Generators::Base
        source_root File.expand_path("templates", __dir__)

        def copy_initializer
          template "fast_exists_initializer.rb", "config/initializers/fast_exists.rb"
        end
      end
    end
  end
end
