source "https://rubygems.org"

gem 'confstruct'
gem 'rake'

group :production do
  # TODO: really?  we really need ruby-oci8?  really?  really really?
  # workflow-archiver gem uses sequel but sequel needs lower level stuff in ruby-oci8?
  gem 'ruby-oci8' # Oracle is required in all environments
end

gem 'whenever'
gem 'workflow-archiver' # does the heavy lifting
gem 'pry-byebug' # for a better console experience


group :deployment do
  gem 'capistrano'
  gem 'capistrano-bundler'
  gem 'dlss-capistrano'
end

gem 'honeybadger'
