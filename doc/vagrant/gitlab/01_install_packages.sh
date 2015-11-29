echo 'Installing dependencies'
apt-get update
apt-get install -y --force-yes curl
apt-get install -y --force-yes openssh-server
apt-get install -y --force-yes ca-certificates
apt-get install -y --force-yes postfix
apt-get install -y --force-yes ruby-dev
apt-get install -y --force-yes git
gem install gitlab

echo 'Configure gitlab installation and run setup'
curl 'https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh' | sudo bash
apt-get install -y gitlab-ce
gitlab-ctl reconfigure
