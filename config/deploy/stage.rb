server 'sul-lyberservices-test.stanford.edu', user: 'lyberadmin', roles: %w{web app db}

Capistrano::OneTimeKey.generate_one_time_key!

set :whenever_environment, 'stage'

# This prevents stage from updating the crontab.
# Adding this because we are trying out the rails-workflow-server which does not need archiving
Rake::Task["whenever:update_crontab"].clear_actions

set :bundle_without, 'deployment'
