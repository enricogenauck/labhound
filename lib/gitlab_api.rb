require 'attr_extras'
require 'octokit'
require 'gitlab'
require 'base64'
require_relative '../config/initializers/constants'

class GitlabApi
  ORGANIZATION_TYPE = 'Organization'
  PREVIEW_MEDIA_TYPE = 'application/vnd.github.moondragon+json'
  API_VERSION = '/api/v3'
  DEVELOPER_LEVEL = '30'

  attr_reader :file_cache, :token, :api_url

  def initialize(token)
    @token = token
    @api_url = Hound::GITLAB_API_URL + API_VERSION
    @file_cache = {}
  end

  def client
    @client ||= Gitlab.client(endpoint: api_url, auth_token: token)
  end

  # TODO: Check if this is needed in Gitlab
  # def scopes
  #   client.scopes(token).join(',')
  # end

  def repos
    client.projects
  end

  def repo(repo_name)
    client.repository(repo_name)
  end

  def add_pull_request_comment(options)
    client.create_commit_comment(
      options[:commit].repo_name,
      options[:commit].sha,
      options[:comment],
      path: options[:filename],
      line: options[:patch_position],
      line_type: 'new'
    )
  end

  def create_hook(project_id, callback_endpoint)
    hook = client.add_project_hook(
      project_id,
      callback_endpoint,
      merge_requests_events: 1
    )

    if block_given?
      yield hook
    elsif hook_already_exists?(hook)
      true
    else
      hook
    end
  end

  def remove_hook(_, hook_id)
    response = client.delete_hook(hook_id)

    if block_given?
      yield
    else
      response
    end
  end

  def pull_request_comments(project_id, merge_request_id)
    client.merge_request_comments(project_id, merge_request_id)
  end

  def pull_request_files(project_id, merge_request_id)
    client.merge_request_changes(project_id, merge_request_id)
  end

  def file_contents(project_id, filename, sha)
    file_cache["#{project_id}/#{sha}/#{filename}"] ||=
      client.file_contents(project_id, filename, sha)
  end

  def create_pending_status(full_repo_name, sha, description)
    create_status(
      repo: full_repo_name,
      sha: sha,
      state: 'pending',
      description: description
    )
  end

  def create_success_status(repo_id, sha, description)
    create_status(
      repo: repo_id,
      sha: sha,
      state: 'success',
      description: description
    )
  end

  def create_error_status(full_repo_name, sha, description, target_url = nil)
    create_status(
      repo: full_repo_name,
      sha: sha,
      state: 'error',
      description: description,
      target_url: target_url
    )
  end

  def add_collaborator(project_id, user_name, access_level=DEVELOPER_LEVEL)
    user_id = find_id(user_name)

    client.add_team_member(
      project_id,
      user_id,
      access_level
    )
  end

  def remove_collaborator(project_id, user_name)
    user_id = find_id(user_name)

    client.remove_team_member(
      project_id,
      user_id
    )
  end

  private

  def authorized_repos(repos)
    repos.select { |repo| repo.permissions.admin }
  end

  def create_status(repo:, sha:, state:, description:, target_url: nil)
    client.create_commit_comment(
      repo,
      sha,
      description
    )
  rescue Octokit::NotFound
    # noop
  end

  def find_id(user_name)
    candidates = client.users(search: user_name)
    candidates.detect{|c| c.username == user_name}.id
  end

  def hook_already_exists?(hook)
    if hook.errors
      messages = hook.errors.map{|e| e['message']}
      ('Hook already exists on this repository').in?(messages)
    end
  end
end
