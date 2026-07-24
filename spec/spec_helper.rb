# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/benchmarks/"
  minimum_coverage 95
end

require "active_record"
require_relative "../lib/fast_exists"

# Set up in-memory SQLite database for testing
ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:"
)

# Create test tables
ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :email
    t.string :username
    t.timestamps
  end

  create_table :products, force: true do |t|
    t.string :sku
    t.timestamps
  end
end

# Define mock test model
class User < ActiveRecord::Base
  include FastExists::ActiveRecord::Extension
  fast_exists :email
  fast_exists :username
end

class Product < ActiveRecord::Base
  include FastExists::ActiveRecord::Extension
  fast_exists :sku
end

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    FastExists.reset_stats!
    User.delete_all
    Product.delete_all
  end
end
