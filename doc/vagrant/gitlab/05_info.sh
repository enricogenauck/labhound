printf "\n\n\n*******************************************\n"
echo "Your Gitlab access data:"
echo "Url: http://gitlab.vagrant.dev"
echo "User: root"
echo "Password: 5iveL!fe"

printf "\n\n\n*******************************************\n"
echo "Your development variables:"
echo "GITLAB_API_URL=http://gitlab.vagrant.dev"
echo "GITLAB_APPLICATION_KEY=$(gitlab-rails runner 'puts Doorkeeper::Application.last.uid')"
echo "GITLAB_APPLICATION_SECRET=$(gitlab-rails runner 'puts Doorkeeper::Application.last.secret')"
echo "HOUND_GITLAB_TOKEN=$(gitlab-rails runner 'puts User.find(2).authentication_token')"
echo "HOUND_GITLAB_USERNAME=hound"
echo "HOST=labhound.vagrant.dev:5000"
