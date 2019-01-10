set :output, 'log/crondebug.log'

job_type :rake, "cd :path && ROBOT_ENVIRONMENT=:environment /usr/local/rvm/bin/rvm default do bundle exec rake :task --silent :output"

every 15.minutes, roles: [:app]  do
  rake 'run_archiver'
end
