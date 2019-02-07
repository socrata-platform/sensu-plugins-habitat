# frozen_string_literal: true

apt_update 'default'

# The sensu-plugin gem depends on the json native gem.
package 'build-essential'

directory node['build_dir'] do
  recursive true
  action :delete
end

execute 'Copy everything into the build dir' do
  command "cp -a #{node['staging_dir']} #{node['build_dir']}"
end

hab_install 'default'

hab_sup 'default'

execute 'Generate a signing key for our test stub packages' do
  command 'hab origin key generate socratest'
  not_if 'hab origin key export socratest'
end

origin = 'socratest'
hab_dir = "#{node['build_dir']}/test/fixtures/habitat-plans"

%w[
  dummy-ok1
  dummy-ok2
  dummy-ok3
  dummy-warning1
  dummy-warning2
  dummy-critical1
  dummy-unknown1
].each do |plan|
  execute "Build #{origin}/#{plan}" do
    command "hab pkg build -R #{plan}"
    cwd hab_dir
    environment HAB_ORIGIN: origin
    not_if { File.exist?("/hab/pkgs/#{origin}/#{plan}") }
  end

  execute "Install #{origin}/#{plan}" do
    command(
      lazy do
        file = File.read("#{hab_dir}/results/last_build.env")
                   .match(/^pkg_artifact=(.*)$/)[1]
        "hab pkg install #{hab_dir}/results/#{file}"
      end
    )
    not_if { File.exist?("/hab/pkgs/#{origin}/#{plan}") }
  end

  hab_service "#{origin}/#{plan}"
end

ruby_block 'Give Habitat 30s to run all health checks at least once' do
  block do
    sleep(30)
  end
end

apt_repository 'sensu' do
  uri 'http://repositories.sensuapp.org/apt'
  key 'http://repositories.sensuapp.org/apt/pubkey.gpg'
  distribution node['lsb']['codename']
  components %w[main]
end

package 'sensu' do
  version node['sensu_version'] unless node['sensu_version'].nil?
end

execute 'Install Bundler' do
  cwd node['build_dir']
  command '/opt/sensu/embedded/bin/gem install bundler'
  not_if '/opt/sensu/embedded/bin/ruby -e "require \'bundler\'"'
end

execute 'Bundle install' do
  cwd node['build_dir']
  command '/opt/sensu/embedded/bin/bundle install --without=development'
end

execute 'Build plugin gem' do
  cwd node['build_dir']
  command 'SIGN_GEM=false /opt/sensu/embedded/bin/gem build ' \
          'sensu-plugins-habitat.gemspec'
end

execute 'Install plugin gem' do
  cwd node['build_dir']
  command '/opt/sensu/embedded/bin/gem install sensu-plugins-habitat-*.gem'
end
