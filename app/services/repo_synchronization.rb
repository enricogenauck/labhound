class RepoSynchronization
  pattr_initialize :user
  attr_reader :user

  def start
    user.repos.clear
    repos = api.repos

    Repo.transaction do
      repos.each do |resource|
        attributes = repo_attributes(resource.to_hash)
        user.repos << Repo.find_or_create_with(attributes)
      end
    end
  end

  private

  def api
    @api ||= GitlabApi.new(user.token)
  end

  def repo_attributes(attributes)
    owner = upsert_owner(attributes['owner'])

    {
      private: !!attributes['public'],
      github_id: attributes['id'],
      full_github_name: attributes['path_with_namespace'],
      in_organization: owner && owner.organization,
      owner: owner
    }
  end

  def upsert_owner(owner_attributes)
    if owner_attributes.present?
      Owner.upsert(
        github_id: owner_attributes['id'],
        name: owner_attributes['name'],
        organization: owner_attributes['type'] == GitlabApi::ORGANIZATION_TYPE
      )
    end
  end
end
