# frozen_string_literal: true

require "spec_helper"

RSpec.describe FastExists::ActiveRecord::Extension do
  describe "Generated methods and lookup flow" do
    it "returns false immediately without DB queries when filter does not contain key" do
      expect(User.email_exists?("nonexistent@example.com")).to be false
      expect(FastExists.stats[:queries_avoided]).to eq(1)
      expect(FastExists.stats[:database_lookups]).to eq(0)
    end

    it "adds record to filter on commit and verifies existence" do
      user = User.create!(email: "alice@example.com", username: "alice")

      expect(User.email_exists?("alice@example.com")).to be true
      expect(User.username_exists?("alice")).to be true
      expect(User.email_available?("alice@example.com")).to be false
      expect(User.email_available?("bob@example.com")).to be true
    end

    it "supports generic fast_exists? and fast_available? methods" do
      User.create!(email: "charlie@example.com", username: "charlie")

      expect(User.fast_exists?(:email, "charlie@example.com")).to be true
      expect(User.fast_available?(:email, "charlie@example.com")).to be false
    end

    it "rebuilds filter from database" do
      # Create record directly bypassing callback
      User.insert_all([{ email: "bulk@example.com", username: "bulk" }])

      # Filter initially doesn't know about bulk record
      expect(User.email_exists?("bulk@example.com")).to be false

      # Rebuild filter
      User.rebuild_fast_exists!

      # Now filter knows!
      expect(User.email_exists?("bulk@example.com")).to be true
    end

    it "provides model-level fast_exists_stats" do
      stats = User.fast_exists_stats
      expect(stats).to have_key(:email)
      expect(stats).to have_key(:username)
      expect(stats[:email][:backend]).to eq(:memory)
    end
  end
end
