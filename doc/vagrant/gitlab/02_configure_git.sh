echo 'Generating vagrant ssh keys for git authentication'
ssh-keygen -f /home/vagrant/.ssh/id_rsa -t rsa -N ''
ssh-keyscan -H localhost >> ~/.ssh/known_hosts
eval '$(ssh-agent -s)'
ssh-add | true

echo 'Configuring git credentials'
git config --global user.email 'labhound@localhost'
git config --global user.name 'labhound'
