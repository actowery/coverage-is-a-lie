# frozen_string_literal: true

require "timeout"

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    enable_coverage :branch
    minimum_coverage line: 100, branch: 100
    add_filter "/spec/"
  end
end

require_relative "../lib/date_utils"

RSpec.configure do |config|
  config.around(:each) do |example|
    Timeout.timeout(5) { example.run }
  rescue Timeout::Error
    raise RSpec::Expectations::ExpectationNotMetError, "example timed out after 5 seconds"
  end
end
