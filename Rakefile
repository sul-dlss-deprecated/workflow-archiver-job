require 'rubygems'
require 'rake'

task :default => nil

desc 'Run the workflow archiver'
task :run_archiver do
  fail 'ROBOT_ENVIRONMENT variable is required' unless ENV['ROBOT_ENVIRONMENT']
  system('bin/run_archiver')
end
