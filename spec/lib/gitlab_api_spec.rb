require 'spec_helper'
require 'attr_extras'
require 'lib/gitlab_api'
require 'json'

describe GitlabApi do
  describe '#repos' do
    it 'fetches all repos from Github' do
      token = 'something'
      api = described_class.new(token)
      stub_repos_requests(token)

      repos = api.repos

      expect(repos.size).to eq 2
    end
  end

  describe '#scopes' do
    skip 'Check if this is needed in Gitlab'
    # TODO: Check if this is needed in Gitlab
    # it 'returns scopes as a string' do
    #   token = 'token'
    #   api = described_class.new(token)
    #   stub_scopes_request(token: token, scopes: 'repo,user:email')
    #
    #   scopes = api.scopes
    #
    #   expect(scopes).to eq 'repo,user:email'
    # end
  end

  describe '#file_contents' do
    context 'used multiple times with same arguments' do
      it 'requests file content once' do
        github = described_class.new(Hound::GITLAB_TOKEN)
        repo = 'jimtom/wow'
        filename = '.hound.yml'
        sha = 'abc123'

        stub_contents_request(
          repo_name: repo,
          sha: sha,
          file: filename
        )

        expect(github.client).to receive(:file_contents).with(
          repo,
          filename,
          sha
        ).once.and_call_original

        contents = github.file_contents(repo, filename, sha)
        same_contents = github.file_contents(repo, filename, sha)

        expect(contents).to be_present
        expect(same_contents).to eq contents
      end
    end
  end

  describe '#create_hook' do
    context 'when hook does not exist' do
      it 'creates pull request web hook' do
        callback_endpoint = 'http://example.com'
        token = 'something'
        api = described_class.new(token)
        request = stub_hook_creation_request(
          full_repo_name,
          callback_endpoint,
          token
        )

        api.create_hook(full_repo_name, callback_endpoint)

        expect(request).to have_been_requested
      end

      it 'yields hook' do
        callback_endpoint = 'http://example.com'
        token = 'something'
        api = described_class.new(token)
        request = stub_hook_creation_request(
          full_repo_name,
          callback_endpoint,
          token
        )
        yielded = false

        api.create_hook(full_repo_name, callback_endpoint) do |hook|
          yielded = true
        end

        expect(request).to have_been_requested
        expect(yielded).to be_truthy
      end
    end

    context 'when hook already exists' do
      it 'does not raise' do
        callback_endpoint = 'http://example.com'
        stub_failed_hook_creation_request(full_repo_name, callback_endpoint)
        api = described_class.new(Hound::GITLAB_TOKEN)

        expect do
          api.create_hook(full_repo_name, callback_endpoint)
        end.not_to raise_error
      end

      it 'returns true' do
        callback_endpoint = 'http://example.com'
        stub_failed_hook_creation_request(full_repo_name, callback_endpoint)
        api = described_class.new(Hound::GITLAB_TOKEN)

        expect(api.create_hook(full_repo_name, callback_endpoint)).to eq true
      end
    end
  end

  describe '#remove_hook' do
    it 'removes pull request web hook' do
      hook_id = '123'
      stub_hook_removal_request(full_repo_name, hook_id)
      api = described_class.new(Hound::GITLAB_TOKEN)

      response = api.remove_hook(full_repo_name, hook_id)

      expect(response).to be_truthy
    end

    it 'yields given block' do
      hook_id = '123'
      stub_hook_removal_request(full_repo_name, hook_id)
      api = described_class.new(Hound::GITLAB_TOKEN)
      yielded = false

      api.remove_hook(full_repo_name, hook_id) do
        yielded = true
      end

      expect(yielded).to eq true
    end
  end

  describe '#pull_request_files' do
    it 'returns changed files in a pull request' do
      api = described_class.new(Hound::GITLAB_TOKEN)
      pull_request = double('PullRequest', full_repo_name: full_repo_name)
      pr_number = 123
      commit_sha = 'abc123'
      stub_pull_request_files_request(pull_request.full_repo_name, pr_number)
      stub_contents_request(
        repo_name: pull_request.full_repo_name,
        sha: commit_sha
      )

      files = api.pull_request_files(pull_request.full_repo_name, pr_number)

      expect(files.size).to eq(1)
      expect(files.first.new_path).to eq 'config/unicorn.rb'
    end
  end

  describe '#add_pull_request_comment' do
    it 'adds comment to GitHub pull request' do
      api = described_class.new('authtoken')
      pull_request_number = 2
      comment = 'test comment'
      commit_sha = 'commitsha'
      file = 'test.rb'
      patch_position = 123
      commit = double('Commit', repo_name: repo_id, sha: commit_sha)
      request = stub_comment_request(
        repo_id,
        pull_request_number,
        comment,
        commit_sha,
        file,
        patch_position
      )

      api.add_pull_request_comment(
        pull_request_number: pull_request_number,
        commit: commit,
        comment: 'test comment',
        filename: file,
        patch_position: patch_position
      )

      expect(request).to have_been_requested
    end
  end

  describe '#pull_request_comments' do
    it 'returns comments added to pull request' do
      api = described_class.new(Hound::GITLAB_TOKEN)
      pull_request = double('PullRequest', full_repo_name: full_repo_name)
      pull_request_id = 253
      commit_sha = 'abc253'
      expected_comment = "inline if's and while's are not violations?"
      stub_pull_request_comments_request(
        pull_request.full_repo_name,
        pull_request_id
      )
      stub_contents_request(
        repo_name: pull_request.full_repo_name,
        sha: commit_sha
      )

      comments = api.pull_request_comments(
        pull_request.full_repo_name,
        pull_request_id
      )

      expect(comments.size).to eq(2)
      expect(comments.first.note).to eq expected_comment
    end
  end

  describe '#create_pending_status' do
    it 'makes request to GitHub for creating a pending status' do
      api = described_class.new(Hound::GITLAB_TOKEN)
      request = stub_status_request(
        'test/repo',
        'sha',
        'pending',
        'description'
      )

      api.create_pending_status('test/repo', 'sha', 'description')

      expect(request).to have_been_requested
    end

    describe 'when setting the status returns 404' do
      it 'does not crash' do
        sha = 'abc'
        api = described_class.new(Hound::GITLAB_TOKEN)
        stub_failed_status_creation_request(
          full_repo_name,
          sha,
          'pending',
          'description'
        )

        expect do
          api.create_pending_status(full_repo_name, sha, 'description')
        end.not_to raise_error
      end
    end
  end

  describe '#create_success_status' do
    it 'makes request to GitHub for creating a success status' do
      api = described_class.new(Hound::GITLAB_TOKEN)
      request = stub_status_request(
        'repo_id',
        'sha',
        'success',
        'description'
      )

      api.create_success_status('repo_id', 'sha', 'description')

      expect(request).to have_been_requested
    end
  end

  describe '#create_error_status' do
    it 'makes request to GitHub for creating an error status' do
      api = described_class.new(Hound::GITLAB_TOKEN)
      request = stub_status_request(
        'test/repo',
        'sha',
        'error',
        'description'
      )

      api.create_error_status('test/repo', 'sha', 'description')

      expect(request).to have_been_requested
    end
  end

  describe '#add_collaborator' do
    it 'makes a request to GitHub' do
      username = 'houndci'
      api = described_class.new(token)
      request = stub_add_collaborator_request(username, repo_id, token)

      api.add_collaborator(repo_id, username)

      expect(request).to have_been_requested
    end
  end

  describe '#remove_collaborator' do
    it 'makes a request to GitHub' do
      username = 'houndci'
      api = described_class.new(token)
      request = stub_remove_collaborator_request(
        username,
        full_repo_name,
        token
      )

      api.remove_collaborator(full_repo_name, username)

      expect(request).to have_been_requested
    end
  end

  def token
    'github_token'
  end

  def full_repo_name
    'foo/bar'
  end

  def repo_id
    '23'
  end
end
