Vagrant.configure(2) do |config|

  config.vm.define 'gitlab' do |gitlab|
    install_script     = 'https://packages.gitlab.com/install/' \
                         'repositories/gitlab/gitlab-ce/script.deb.sh'
    custom_hostname    = 'gitlab.vagrant.dev'

    gitlab.config.vm.box = 'ubuntu/trusty64'
    gitlab.config.vm.hostname = custom_hostname
    gitlab.config.landrush.enabled = true

    gitlab.config.vm.provider 'virtualbox' do |v, _|
      v.cpus = 2
      v.memory = 2048
    end

    # Generate ssh keys for git authentication
    gitlab.config.vm.provision 'shell', privileged: false, inline: <<-SHELL
      ssh-keygen -f /home/vagrant/.ssh/id_rsa -t rsa -N ''
      ssh-keyscan -H localhost >> ~/.ssh/known_hosts
      eval "$(ssh-agent -s)"
      ssh-add
    SHELL

    # Install dependencies
    gitlab.config.vm.provision 'shell', inline: <<-SHELL
      apt-get update
      apt-get install -y curl
      apt-get install -y openssh-server
      apt-get install -y ca-certificates
      apt-get install -y postfix
      apt-get install -y ruby-dev
      apt-get install -y git
      gem install gitlab
    SHELL

    # Configure git credentials
    gitlab.config.vm.provision 'shell', privileged: false, inline: <<-SHELL
      git config --global user.email "labhound@localhost"
      git config --global user.name "labhound"
    SHELL

    # Configure gitlab installation and run setup
    gitlab.config.vm.provision 'shell', inline: <<-SHELL
      curl #{install_script} | sudo bash
      apt-get install -y gitlab-ce
      gitlab-ctl reconfigure
    SHELL


    # Configure test repository in gitlab and add first commit
    gitlab.config.vm.provision 'shell', privileged: false, inline: <<-SHELL
      ruby -e '
        require "gitlab"

        Gitlab.endpoint      = "http://localhost/api/v3"
        Gitlab.private_token = Gitlab.session("root", "5iveL!fe").private_token
        client               = Gitlab::Client.new

        client.create_project "labhound-test"

        key = File.open("/home/vagrant/.ssh/id_rsa.pub").read
        Gitlab.create_ssh_key("root", key)
        sleep 5 # wait for gitlab changes to take effect
      '

      git clone git@localhost:root/labhound-test.git
      cd labhound-test/
      git checkout -b feature
      touch rubyscript.rb
      git add rubyscript.rb
      git commit -m "initial commit"
      git push origin feature
    SHELL
  end
end
