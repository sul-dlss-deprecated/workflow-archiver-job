set :output, '/home/lyberadmin/workflow-archiver-job/current/log/crondebug.log'

every :day, :at => '2:16am' do
 command "BUNDLE_GEMFILE=/home/lyberadmin/workflow-archiver-job/current/Gemfile ROBOT_ENVIRONMENT=#{environment} /usr/local/rvm/wrappers/ruby-1.8.7-p370/ruby /home/lyberadmin/workflow-archiver-job/current/bin/run_archiver"
end
