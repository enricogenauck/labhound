class PullRequest
  pattr_initialize :payload, :token

  FILE_REMOVED_STATUS = 'removed'

  def comments
    @comments ||= user_github.pull_request_comments(repo_id, number)
  end

  def commit_files
    @commit_files ||= modified_commit_files
  end

  def comment_on_violation(violation)
    user_github.add_pull_request_comment(
      pull_request_number: number,
      comment: violation.messages.join('<br>'),
      commit: head_commit,
      filename: violation.filename,
      patch_position: violation.patch_position
    )
  end

  def repository_owner_name
    payload.repository_owner_name
  end

  def opened?
    payload.action == 'open'
  end

  def updated?
    payload.action == 'update'
  end

  def head_commit
    @head_commit ||= Commit.new(repo_id, payload.head_sha, user_github)
  end

  private

  def modified_commit_files
    modified_github_files.map do |github_file|
      CommitFile.new(
        filename: github_file.new_path,
        patch: github_file.diff,
        commit: head_commit
      )
    end
  end

  def modified_github_files
    github_files.select do |github_file|
      !github_file.deleted_file
    end
  end

  def user_github
    @user_github ||= GitlabApi.new(token)
  end

  def github_files
    if updated?
      user_github.commit_files(repo_id, payload.head_sha)
    else
      user_github.pull_request_files(repo_id, number)
    end
  end

  def number
    payload.pull_request_number
  end

  def repo_id
    payload.github_repo_id
  end
end
