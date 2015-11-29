echo 'Creating hound user and test project'
ruby -e '
  require "gitlab"

  Gitlab.endpoint      = "http://localhost/api/v3"
  Gitlab.private_token = Gitlab.session("root", "5iveL!fe").private_token
  client               = Gitlab::Client.new

  client.create_user("mail@example.com", "password", username: "hound").inspect
  client.create_project "labhound-test"
  key = File.open("/home/vagrant/.ssh/id_rsa.pub").read
  Gitlab.create_ssh_key("root", key)
'
gitlab-rails runner "Doorkeeper::Application.create!(name:'labhound', redirect_uri:'http://labhound.vagrant.dev:5000/auth/gitlab/callback')"
gitlab-rails runner "User.update_all(password_expires_at: nil)"
