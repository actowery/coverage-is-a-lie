# frozen_string_literal: true

require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc "Run mutant mutation testing against DateUtils"
task :mutant do
  sh "bundle exec mutant run --usage opensource --integration rspec DateUtils"
end
