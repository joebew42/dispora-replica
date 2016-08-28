set :stage, :test

set :repo_url, "file:///home/vagrant/diaspora_src"
set :branch, ENV['BRANCH'] || "develop"

#role :web, [ENV['SERVER_URL']]
role :app, [ENV['SERVER_URL']]
role :db,  [ENV['SERVER_URL']]

ssh_options = {
  keys: %w(ssh_keys/diaspora),
  forward_agent: true,
  auth_methods: %w(publickey password)
}

set :rvm_type, :system
set :rvm_ruby_version, '2.3.1@diaspora'

set :rails_env, 'development'
set :bundle_without, []

set :assets_roles, [:none] # No assets compile for development

set :keep_releases, 1

server ENV['SERVER_URL'], user: 'diaspora', roles: [], ssh_options: ssh_options

namespace :deploy do
  before :migrate, 'rails:rake:db:drop'
  before :migrate, 'rails:rake:db:setup'
  after :finished, 'diaspora:fixtures:generate_and_load'
end
