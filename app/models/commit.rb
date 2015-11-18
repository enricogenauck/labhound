class Commit
  pattr_initialize :repo_name, :sha, :github
  attr_reader :repo_name, :sha

  def file_content(filename)
    @github.file_contents(repo_name, filename, sha)
  rescue Octokit::NotFound
    ''
  rescue Octokit::Forbidden => exception
    if exception.errors.any? && exception.errors.first[:code] == 'too_large'
      ''
    else
      raise exception
    end
  end
end
