class RepoActivator
  attr_reader :errors

  def initialize(github_token:, repo:)
    @github_token = github_token
    @repo = repo
    @errors = []
  end

  def activate
    change_repository_state_quietly do
      if repo.private?
        add_hound_to_repo && create_webhook && repo.activate
      else
        create_webhook && repo.activate
      end
    end
  end

  def deactivate
    change_repository_state_quietly do
      if repo.private?
        remove_hound_from_repo
      end

      delete_webhook && repo.deactivate
    end
  end

  private

  attr_reader :github_token, :repo

  def change_repository_state_quietly
    yield
  rescue Octokit::Error => error
    add_error(error)
    false
  end

  def remove_hound_from_repo
    github.remove_collaborator(repo.github_id, Hound::GITLAB_USERNAME)
  end

  def add_hound_to_repo
    github.add_collaborator(repo.github_id, Hound::GITLAB_USERNAME)
  end

  def github
    @github ||= GitlabApi.new(github_token)
  end

  def create_webhook
    github.create_hook(repo.github_id, builds_url) do |hook|
      repo.update(hook_id: hook.id)
    end
  end

  def delete_webhook
    github.remove_hook(repo.github_id, repo.hook_id) do
      repo.update(hook_id: nil)
    end
  end

  def builds_url
    URI.join("#{protocol}://#{Hound::HOST}", 'builds').to_s
  end

  def protocol
    if Hound::HTTPS_ENABLED
      'https'
    else
      'http'
    end
  end

  def add_error(error)
    error_message = ErrorMessageTranslation.from_error_response(error)
    errors.push(error_message).compact!
  end
end
