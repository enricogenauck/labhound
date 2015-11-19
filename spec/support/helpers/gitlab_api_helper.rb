module GitlabApiHelper
  def stub_add_collaborator_request(username, repo_name, user_token)
    stub_search_user_request(username, user_token)

    stub_request(:post, "#{gitlab_url}/api/v3/projects/#{repo_name}/members")
      .with(
        headers: {
          'Private-Token' => user_token, 'Accept' => 'application/json'
        },
        body: 'user_id=1&access_level=30'
      ).to_return(
        status: 204
      )
  end

  def stub_search_user_request(username, user_token)
    stub_request(:get, "#{gitlab_url}/api/v3/users?search=#{username}")
      .with(
        headers: {
          'Private-Token' => user_token, 'Accept' => 'application/json'
        }
      ).to_return(
          status: 200,
          body: fixture('gitlab_users.json').gsub('testing_user', username)
      )
  end

  def stub_remove_collaborator_request(username, repo_id, user_token)
    stub_search_user_request(username, user_token)

    stub_request(
      :delete,
      "#{gitlab_api_url}/projects/#{repo_id}/members/1"
    ).with(
      headers: auth_header(user_token)
    ).to_return(
      status: 204
    )
  end

  def stub_repo_request(repo_id, token)
    stub_request(
      :get,
      "#{gitlab_api_url}/projects/#{repo_id}"
    ).with(headers: auth_header(token))
    .to_return(
      status: 200,
      body: fixture('repo.json').gsub('testing/repo', repo_id.to_s),
      headers: { 'Content-Type' => 'application/json; charset=utf-8' }
    )
  end

  def stub_repo_with_org_request(repo_name, token = hound_token)
    stub_request(
      :get,
      "https://api.github.com/repos/#{repo_name}"
    ).with(
      headers: { 'Authorization' => "token #{token}" }
    ).to_return(
      status: 200,
      body: File.read('spec/support/fixtures/repo_with_org.json'),
      headers: { 'Content-Type' => 'application/json; charset=utf-8' }
    )
  end

  def stub_hook_creation_request(repo_id, callback_endpoint, token)
    callback_endpoint = CGI.escape(callback_endpoint)

    stub_request(:post, "#{gitlab_url}/api/v3/projects/#{repo_id}/hooks")
      .with(
        body: "url=#{callback_endpoint}&merge_requests_events=1",
        headers: auth_header(token)
      ).to_return(
        status: 200,
        body: fixture('github_hook_creation_response.json'),
        headers: { 'Content-Type' => 'application/json; charset=utf-8' }
    )
  end

  def stub_failed_hook_creation_request(repo_id, callback_endpoint)
    callback_endpoint = CGI.escape(callback_endpoint)

    stub_request(:post, "#{gitlab_url}/api/v3/projects/#{repo_id}/hooks")
      .with(
        body: "url=#{callback_endpoint}&merge_requests_events=1",
        headers: auth_header(hound_token)
      ).to_return(
        status: 422,
        body: File.read('spec/support/fixtures/failed_hook.json'),
        headers: { 'Content-Type' => 'application/json; charset=utf-8' }
      )
  end

  def stub_failed_status_creation_request(repo_id, sha, state, description)
    stub_request(
      :post,
      "#{gitlab_api_url}/projects/#{repo_id}/repository/commits/#{sha}/comments"
    ).with(
      headers: auth_header(hound_token),
      body: status_request_body(description)
    ).to_return(
      status: 404,
      headers: { 'Content-Type' => 'application/json; charset=utf-8' }
    )
  end

  def stub_hook_removal_request(full_repo_name, hook_id, token = nil)
    url = "#{gitlab_api_url}/hooks/#{hook_id}"
    token ||= hound_token

    stub_request(:delete, url)
      .with(headers: auth_header(token))
      .to_return(
        status: 200,
        body: fixture('hook.json')
      )
  end

  def stub_commit_request(full_repo_name, commit_sha)
    stub_request(
      :get,
      "https://api.github.com/repos/#{full_repo_name}/commits/#{commit_sha}"
    ).with(
      headers: { 'Authorization' => "token #{hound_token}" }
    ).to_return(
      status: 200,
      body: File.read('spec/support/fixtures/commit.json'),
      headers: { 'Content-Type' => 'application/json; charset=utf-8' }
    )
  end

  def stub_pull_request_files_request(repo_id, pull_request_number)
    stub_request(
      :get,
      "#{gitlab_api_url}/projects/#{repo_id}/merge_request/" \
      "#{pull_request_number}/changes"
    ).with(headers: auth_header(hound_token))
    .to_return(
      status: 200,
      body: File.read('spec/support/fixtures/pull_request_files.json'),
      headers: { 'Content-Type' => 'application/json; charset=utf-8' }
    )
  end

  def stub_contents_request(options = {})
    fixture_file = options.fetch(:fixture, 'contents.json')
    file    = options.fetch(:file, 'config/unicorn.rb')
    repo    = options[:repo_name]
    sha     = options[:sha]

    stub_request(
      :get,
      "#{gitlab_api_url}/projects/#{repo}/repository/blobs/" \
      "#{sha}?filepath=#{file}"
    ).with(headers: auth_header(hound_token)
    ).to_return(
      status: 200,
      body: fixture(fixture_file),
      headers: { 'Content-Type' => 'text/plain; charset=utf-8' }
    )
  end

  def stub_scopes_request(token: 'token', scopes: 'public_repo,user:email')
    stub_request(:get, 'https://api.github.com/user')
      .with(
        headers: {
          'Accept' => 'application/vnd.github.v3+json',
          'Authorization' => "token #{token}",
          'Content-Type' => 'application/json',
          'User-Agent' => 'Octokit Ruby Gem 4.1.1'
        }
      )
      .to_return(
        status: 200, body: '', headers: { 'X-OAuth-Scopes' => scopes }
      )
  end

  private

  def stub_repos_requests(token)
    stub_request(
      :get,
      "#{gitlab_api_url}/projects"
    ).with(
      headers: { 'PRIVATE-TOKEN' => token }
    ).to_return(
      status: 200,
      body: File.read("#{fixture_dir}/github_repos_response_for_jimtom.json"),
      headers: { 'Content-Type' => 'application/json; charset=utf-8' }
    )
  end

  def stub_comment_request(repo_id, _, comment, sha, file, line_number)
    stub_request(
      :post,
      "#{gitlab_api_url}/projects/#{repo_id}/repository/commits/#{sha}/comments"
    ).with(body: comment_body(file, line_number, comment))
    .to_return(status: 200)
  end

  def stub_pull_request_comments_request(repo_id, pull_request_number)
    comments_body = fixture('pull_request_comments.json')
    url           = "#{gitlab_api_url}/projects/#{repo_id}/merge_request/" \
                    "#{pull_request_number}/comments"
    headers       = { 'Content-Type' => 'application/json; charset=utf-8' }

    stub_request(:get, url)
      .with(headers: auth_header(hound_token))
      .to_return(status: 200, body: comments_body, headers: headers)
    stub_request(:get, "#{url}?page=2&per_page=100")
      .to_return(status: 200, body: '[]', headers: headers)
  end

  def stub_status_requests(repo_name, sha)
    stub_status_request(
      repo_name,
      sha,
      'pending',
      'Hound is busy reviewing changes...'
    )
    stub_status_request(
      repo_name,
      sha,
      'success',
      anything
    )
  end

  def stub_status_request(repo_id, sha, state, description, target_url = nil)
    stub_request(
      :post,
      "#{gitlab_api_url}/projects/#{repo_id}/repository/commits/#{sha}/comments"
    ).with(
      headers: auth_header(hound_token),
      body: status_request_body(description, state, target_url)
    ).to_return(status_request_return_value)
  end

  def status_request_return_value
    {
      status: 201,
      body: File.read('spec/support/fixtures/github_status_response.json'),
      headers: { 'Content-Type' => 'application/json; charset=utf-8' }
    }
  end

  def status_request_body(description, _ = nil, _ = nil)
    if description.respond_to?(:to_str)
      "note=#{URI.escape(description)}"
    else
      description
    end
  end

  def comment_body(path, line, comment)
    "path=#{path}&" \
    "line=#{line}&" \
    'line_type=new&' \
    "note=#{URI.escape(comment)}"
  end

  def hound_token
    Hound::GITLAB_TOKEN
  end

  def fixture_dir
    'spec/support/fixtures'
  end

  def fixture(file_name)
    File.read("#{fixture_dir}/#{file_name}")
  end

  def gitlab_url
    Hound::GITLAB_API_URL
  end

  def gitlab_api_url
    Hound::GITLAB_API_URL + GitlabApi::API_VERSION
  end

  def auth_header(token)
    {'Private-Token' => token, 'Accept' => 'application/json'}
  end
end
