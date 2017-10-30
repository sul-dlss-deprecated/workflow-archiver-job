set :application, 'workflow-archiver-job'
set :repo_url, 'https://github.com/sul-dlss/workflow-archiver-job.git'

# Default branch is :master
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# Default deploy_to directory is /var/www/my_app
set :deploy_to, "/home/lyberadmin/#{fetch(:application)}"

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :stages, %W(development stage production dev)

set :linked_dirs, %w(log config/environments)

# To compile native Oracle libraries in ruby-oci8 gem
set :bundle_env_variables, :ld_library_path => '/usr/lib/oracle/11.2/client64/lib:$LD_LIBRARY_PATH'

set :whenever_environment, fetch(:stage)

set :bundle_without, %w(deployment test development).join(' ')

namespace :deploy do
end
