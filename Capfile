# Initial setup run from laptop
# 1) Setup directory structure on remote VM
#   $ cap dev deploy:setup
# 2) Manually copy environment specific config file to $application/shared/config/environments.
#      Only necessary for initial install
# 3) Copy project from source control to remote
#   $ cap dev deploy:update
# 4) Setup crontab
#   For some reason, the whenever cap task doesn't fire after a deploy.  You need to enter this:
#   $ bundle exec whenever -i workflow-archiver --update-crontab --set 'environment=test'


load 'deploy' if respond_to?(:namespace) # cap2 differentiator

require 'dlss/capistrano'

set :whenever_command, "bundle exec whenever"
set :whenever_environment, defer { deploy_env }
set :whenever_roles, :app
require "whenever/capistrano"

set :application, "workflow-archiver-job"

task :dev do
  role :app, "sul-lyberservices-dev.stanford.edu"
  set :bundle_without,  []                        # deploy all the gem groups on the dev VM
  set :deploy_env, "development"
end

task :testing do
  role :app, "sul-lyberservices-test.stanford.edu"
  set :deploy_env, "test"
end

task :production do
  role :app, "sul-lyberservices-prod.stanford.edu"
  set :deploy_env, "production"
end

set :user, "lyberadmin"
set :repository do
  msg = "Sunetid: "
  sunetid = Capistrano::CLI.ui.ask(msg)
  "ssh://#{sunetid}@corn.stanford.edu/afs/ir/dev/dlss/git/lyberteam/workflow-archiver-job.git"
end
set :deploy_via, :copy
set :copy_cache, :true
set :copy_exclude, [".git"]
set :deploy_to, "/home/#{user}/#{application}"

# Setup the shared_children directories before deploy:setup
before "deploy:setup", "dlss:set_shared_children"
set :shared_children, %w(log config/environments)

# Set the LD_LIBRARY_PATH, and set the shared children before deploy:update
before "deploy:update", "dlss:set_ld_library_path"

namespace :dlss do
  task :set_ld_library_path do
    default_environment["LD_LIBRARY_PATH"] = "/usr/lib/oracle/11.2/client64/lib:$LD_LIBRARY_PATH"
  end
end

namespace :deploy do

     desc <<-DESC
           This overrides the default :finalize_update since we don't care about \
           rails specific directories
     DESC
     task :finalize_update, :except => { :no_release => true } do
       run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)

       shared_children.map do |d|
         run "rm -rf #{latest_release}/#{d}"
         run "ln -s #{shared_path}/#{d.split('/').last} #{latest_release}/#{d}"
       end
     end

end
