set :output, '/home/lyberadmin/workflow-archiver-job/current/log/crondebug.log'

every 15.minutes, :roles => [:app]  do
 command "BUNDLE_GEMFILE=/home/lyberadmin/workflow-archiver-job/current/Gemfile ROBOT_ENVIRONMENT=#{environment} /usr/local/rvm/wrappers/default/ruby /home/lyberadmin/workflow-archiver-job/current/bin/run_archiver"
end
