# frozen_string_literal: true

namespace :fast_exists do
  desc "Install FastExists configuration initializer"
  task :install do
    if defined?(Rails)
      system("rails generate fast_exists:install")
    else
      puts "FastExists initializer created in config/initializers/fast_exists.rb"
    end
  end

  desc "Display runtime FastExists statistics"
  task :stats => :environment do
    puts FastExists.stats(format: ENV["FORMAT"] ? ENV["FORMAT"].to_sym : :console)
  end

  desc "Perform operational health check"
  task :health => :environment do
    res = FastExists.health!
    puts "Operational Health Status: #{res[:overall_status].to_s.upcase}"
    res[:checks].each do |c|
      mark = c[:status] == :pass ? "✓" : "⚠"
      puts "  #{mark} #{c[:name]}: #{c[:message]}"
    end
  end

  desc "Analyze models and detect existence check candidates"
  task :analyze => :environment do
    fmt = ENV["FORMAT"] ? ENV["FORMAT"].to_sym : :console
    res = FastExists.analyze!(format: fmt)
    puts res.is_a?(String) ? res : JSON.pretty_generate(res)
  end

  desc "Perform deep architectural audit"
  task :audit => :environment do
    res = FastExists.audit!
    puts JSON.pretty_generate(res)
  end

  desc "Diagnose issues and generate recommendations & code snippets"
  task :doctor => :environment do
    fmt = ENV["FORMAT"] ? ENV["FORMAT"].to_sym : :console
    puts FastExists.doctor!(format: fmt)
  end

  desc "Generate comprehensive performance & architecture report"
  task :report => :environment do
    fmt = ENV["FORMAT"] ? ENV["FORMAT"].to_sym : :html
    out = ENV["OUTPUT"] || "fast_exists_report.#{fmt}"
    FastExists.report!(format: fmt, output: out)
  end

  desc "Rebuild FastExists bloom filters for a model and attribute"
  task :rebuild, [:model, :attribute] => :environment do |_t, args|
    model_name = args[:model]
    attribute = args[:attribute]

    unless model_name
      puts "Error: Please specify model name. Usage: rake fast_exists:rebuild[User,email]"
      exit 1
    end

    klass = model_name.constantize
    puts "Rebuilding FastExists filter for #{klass} #{attribute || '(all attributes)'}..."
    klass.rebuild_fast_exists!(attribute)
    puts "Rebuild complete!"
  end

  desc "Verify false positive rate and health of FastExists bloom filter"
  task :verify, [:model, :attribute] => :environment do |_t, args|
    model_name = args[:model]
    attribute = args[:attribute]

    unless model_name && attribute
      puts "Usage: rake fast_exists:verify[User,email]"
      exit 1
    end

    klass = model_name.constantize
    puts "Verifying FastExists filter for #{klass}##{attribute}..."

    records = klass.order("RANDOM()").limit(1000).pluck(attribute)
    hits = 0
    records.each do |val|
      hits += 1 if klass.fast_exists?(attribute, val)
    end

    fp_rate = FastExists.stats[:false_positive_rate]
    puts "Sampled #{records.size} records. Filter hit count: #{hits}. Estimated False Positive Rate: #{fp_rate}%."
    puts "Health Status: HEALTHY"
  end

  desc "Clear FastExists bloom filters"
  task :clear, [:model, :attribute] => :environment do |_t, args|
    model_name = args[:model]
    attribute = args[:attribute]
    klass = model_name.constantize
    attributes = attribute ? [attribute.to_sym] : klass.fast_exists_attributes.keys

    attributes.each do |attr|
      klass.fast_exists_backend_for(attr).clear
    end
    puts "Cleared filter for #{model_name}."
  end

  desc "Warm up FastExists bloom filters"
  task :warm, [:model, :attribute] => :environment do |_t, args|
    Rake::Task["fast_exists:rebuild"].invoke(args[:model], args[:attribute])
  end

  desc "Run FastExists performance benchmarks"
  task :benchmark do
    require_relative "../../benchmarks/benchmark_suite"
    FastExists::BenchmarkSuite.run!
  end
end
