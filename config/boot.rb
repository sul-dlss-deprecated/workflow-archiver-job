require 'rubygems'
require 'bundler/setup'

ROBOT_ROOT = File.expand_path(File.dirname(__FILE__) + "/..")

# Load the environment file based on Environment.  Default to development
environment = ENV['ROBOT_ENVIRONMENT'] ||= 'development'

require 'lyber_core'
require 'dor/workflow_archiver'

env_file = File.expand_path(File.dirname(__FILE__) + "/./environments/#{environment}")
puts "Loading config from #{env_file}"
require env_file
