require 'rails_helper'

describe ActivationsController, '#create' do
  context 'when activation succeeds' do
    it 'returns successful response' do
      membership = create(:membership)
      repo = membership.repo
      activator = double('RepoActivator', activate: true, errors: [])
      allow(RepoActivator).to receive(:new).and_return(activator)
      stub_sign_in(membership.user)

      post :create, repo_id: repo.id, format: :json

      expect(response.code).to eq '201'
      expect(response.body).to eq RepoSerializer.new(repo).to_json
      expect(activator).to have_received(:activate)
      expect(RepoActivator).to have_received(:new)
        .with(repo: repo, github_token: membership.user.token)
      expect(analytics).to have_tracked('Repo Activated')
        .for_user(membership.user)
        .with(
          properties: {
            name: repo.full_github_name,
            private: false,
            revenue: 0
          }
        )
    end
  end

  context 'when activation fails' do
    context 'due to 403 Forbidden from GitHub' do
      it 'returns error response' do
        membership = create(:membership)
        repo = membership.repo
        error_message = 'You must be an admin to add a team membership'
        activator = double(
          'RepoActivator',
          activate: false,
          errors: [error_message]
        )
        allow(RepoActivator).to receive(:new).and_return(activator)
        stub_sign_in(membership.user)

        post :create, repo_id: repo.id, format: :json

        response_body = JSON.parse(response.body)
        expect(response.code).to eq '502'
        expect(response_body['errors']).to match_array(error_message)
        expect(activator).to have_received(:activate)
        expect(RepoActivator).to have_received(:new)
          .with(repo: repo, github_token: membership.user.token)
      end
    end

    it 'tracks failed activation' do
      membership = create(:membership)
      repo = membership.repo
      activator = double(
        'RepoActivator',
        activate: false,
        errors: []
      )
      allow(RepoActivator).to receive(:new).and_return(activator)
      stub_sign_in(membership.user)

      post :create, repo_id: repo.id, format: :json

      expect(analytics).to have_tracked('Repo Activation Failed')
        .for_user(membership.user)
        .with(
          properties: {
            name: repo.full_github_name,
            private: false
          }
        )
    end
  end
end
