Vagrant.configure(2) do |config|
  config.landrush.enabled = true

  config.vm.define 'gitlab' do |gitlab|
    gitlab.vm.box      = 'ubuntu/trusty64'
    gitlab.vm.hostname = 'gitlab.vagrant.dev'
    gitlab.vm.provider 'virtualbox' do |v|
      v.cpus = 2
      v.memory = 2048
    end
    gitlab.vm.provision(
      'shell',
      path: 'doc/vagrant/gitlab/01_install_packages.sh'
    )
    gitlab.vm.provision(
      'shell',
      privileged: false,
      path: 'doc/vagrant/gitlab/02_configure_git.sh'
    )
    gitlab.vm.provision(
      'shell',
      path: 'doc/vagrant/gitlab/03_configure_gitlab.sh'
    )
    gitlab.vm.provision(
      'shell',
      privileged: false,
      path: 'doc/vagrant/gitlab/04_test_checkout.sh'
    )
    gitlab.vm.provision 'shell', path: 'doc/vagrant/gitlab/05_info.sh'
  end

  config.vm.define 'labhound' do |labhound|
    config.vm.provider 'virtualbox' do |v|
      v.memory = 1024
    end

    labhound.vm.box      = 'ubuntu/trusty64'
    labhound.vm.hostname = 'labhound.vagrant.dev'
    labhound.vm.provision 'puppet' do |puppet|
      puppet.manifests_path = 'doc/vagrant/labhound/manifests'
      puppet.module_path = 'doc/vagrant/labhound/modules'
      puppet.options = '--verbose --debug'
    end
  end
end
