class Payload
  pattr_initialize :unparsed_data

  def data
    @data ||= parse_data
  end

  def head_sha
    pull_request.fetch('last_commit', {})['id']
  end

  def github_repo_id
    pull_request['target_project_id']
  end

  def full_repo_name
    repository['namespace'] + '/' + repository['name']
  end

  def pull_request_number
    pull_request['id']
  end

  def action
    pull_request['action']
  end

  def changed_files
    pull_request['changed_files'] || 0
  end

  def ping?
    data['zen']
  end

  def pull_request?
    data['object_kind'] == 'merge_request'
  end

  def repository_owner_id
    # Currently not supported in merge request payload
  end

  def repository_owner_name
    # Currently not supported in merge request payload
  end

  def repository_owner_is_organization?
    # Organizations are not supported in Gitlab currently
    false
  end

  def build_data
    {
      'object_kind' => data['object_kind'],
      'object_attributes' => {
        'id' => pull_request_number,
        'action' => action,
        'target_project_id' => github_repo_id,
        'source' => {
          'name' => repository['name'],
          'namespace' => repository['namespace'],
          'visibility_level' => repository['visibility_level']
        },
        'last_commit' => { 'id' => head_sha }
      }
    }
  end

  def private_repo?
    repository['visibility_level'] == 0
  end

  private

  def parse_data
    if unparsed_data.is_a? String
      Config::Parser.json(unparsed_data)
    else
      unparsed_data
    end
  end

  def pull_request
    data.fetch('object_attributes', {})
  end

  def repository
    @repository ||= pull_request['source']
  end
end
