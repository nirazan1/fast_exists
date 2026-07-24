# frozen_string_literal: true

require_relative "lib/fast_exists/version"

Gem::Specification.new do |spec|
  spec.name          = "fast_exists"
  spec.version       = FastExists::VERSION
  spec.authors       = ["FastExists Team"]
  spec.email         = ["maintainers@fastexists.org"]

  spec.summary       = "Ultra-fast existence checks for Ruby on Rails using probabilistic data structures"
  spec.description   = "FastExists drastically reduces database lookups in Ruby on Rails applications by utilizing thread-safe probabilistic filters (Bloom Filters, Cuckoo Filters, HyperLogLog) while preserving the database as the single source of truth."
  spec.homepage      = "https://github.com/fastexists/fast_exists"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/fastexists/fast_exists"
  spec.metadata["changelog_uri"] = "https://github.com/fastexists/fast_exists/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.glob("{lib,bin,config,app,benchmarks,docs}/**/*") + %w[README.md LICENSE.txt]
  spec.bindir = "bin"
  spec.executables = ["fast_exists"]
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 7.0.0"
  spec.add_dependency "activerecord", ">= 7.0.0"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "sqlite3", ">= 1.4"
  spec.add_development_dependency "simplecov", "~> 0.22"
end
