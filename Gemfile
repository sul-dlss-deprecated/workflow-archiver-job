source "https://rubygems.org"

gem 'confstruct'
gem "workflow-archiver", '~> 2.0'
gem "whenever"
gem "rspec", "~> 3.3"  # for on VM integration tests

group :deployment do
  gem "capistrano", '~> 3.0'
  gem 'capistrano-bundler', '~> 1.1'
  gem "dlss-capistrano"
end

group :production do
  gem 'ruby-oci8'
end
