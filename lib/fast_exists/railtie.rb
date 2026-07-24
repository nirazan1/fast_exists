# frozen_string_literal: true

if defined?(Rails::Railtie)
  module FastExists
    class Railtie < Rails::Railtie
      initializer "fast_exists.active_record" do
        ActiveSupport.on_load(:active_record) do
          include FastExists::ActiveRecord::Extension
        end
      end

      rake_tasks do
        load File.expand_path("tasks/fast_exists.rake", __dir__)
      end
    end
  end
end
