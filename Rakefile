# frozen_string_literal: true

require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc "Run specs with SimpleCov coverage report (demo entry point)"
task :coverage do
  sh "COVERAGE=1 bundle exec rspec"
end

desc "Run mutant mutation testing against DateUtils"
task :mutant do
  sh "bundle exec mutant run --usage opensource --integration rspec DateUtils"
end
