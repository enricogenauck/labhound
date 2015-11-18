require 'spec_helper'
require 'attr_extras'
require 'app/models/payload'
require 'lib/gitlab_api'

describe Payload do
  describe '#changed_files' do
    context 'with pull_request data' do
      it 'returns number of changed files' do
        skip 'TODO: Get number of changed files for merge request event'
        fixture_file = 'spec/support/fixtures/pull_request_opened_event.json'
        payload_json = File.read(fixture_file)
        payload = Payload.new(payload_json)

        expect(payload.changed_files).to eq 1
      end
    end

    context 'with no pull_request data' do
      it 'returns zero' do
        data = '{}'
        payload = Payload.new(data)

        expect(payload.changed_files).to be_zero
      end
    end
  end

  describe '#head_sha' do
    context 'with pull_request data' do
      it 'returns sha' do
        data = File.read(
          'spec/support/fixtures/pull_request_opened_event.json'
        )
        payload = Payload.new(data)

        expect(payload.head_sha)
          .to eq 'da1560886d4f094c3e6c9ef40349f7d38b5d27d7'
      end
    end

    context 'with no pull_request data' do
      it 'returns nil' do
        payload = Payload.new('some_key' => 'something')

        expect(payload.head_sha).to be_nil
      end
    end
  end

  describe '#data' do
    it 'returns data' do
      data = {one: 1}
      payload = Payload.new(data)

      expect(payload.data).to eq data
    end
  end

  describe '#pull_request?' do
    context 'when payload for push of a commit' do
      it 'returns false' do
        push_event = File.read('spec/support/fixtures/push_event.json')
        payload = Payload.new(push_event)

        expect(payload).not_to be_pull_request
      end
    end

    context 'when payload for pull request' do
      it 'returns true' do
        push_event = File.read(
          'spec/support/fixtures/pull_request_opened_event.json'
        )
        payload = Payload.new(push_event)

        expect(payload).to be_pull_request
      end
    end
  end

  describe '#pull_request_number' do
    it 'returns the pull request number' do
      data = File.read(
        'spec/support/fixtures/pull_request_opened_event.json'
      )
      payload = Payload.new(data)

      expect(payload.pull_request_number).to eq 99
    end
  end

  describe '#repository_owner_name' do
    it "returns the owner of the repo's name" do
      skip 'This data is not supported in merge request payload currently'
      data = {
        'repository' => {
          'owner' => {
            'login' => 'thoughtbot'
          }
        }
      }

      payload = Payload.new(data)

      expect(payload.repository_owner_name).to eq 'thoughtbot'
    end
  end

  describe '#repository_owner_id' do
    it "returns the owner of the repo's ID" do
      skip 'This data is not supported in merge request payload currently'
      data = {
        'repository' => {
          'owner' => {
            'id' => 1
          }
        }
      }

      payload = Payload.new(data)

      expect(payload.repository_owner_id).to eq 1
    end
  end

  describe '#repository_owner_is_organization?' do
    skip 'Organizations are not supported in Gitlab currently'
    context 'when the repository owner is a user' do
      it 'returns false' do
        payload_json = {
          'repository' => {
            'owner' => {
              'id' => 1,
              'type' => 'User'
            }
          }
        }
        payload = Payload.new(payload_json)

        expect(payload.repository_owner_is_organization?).to be false
      end
    end

    context 'when the repository owner is an organization' do
      it 'returns true' do
        skip 'Organizations are not supported in Gitlab currently'
        payload_json = {
          'repository' => {
            'owner' => {
              'id' => 1,
              'type' => 'Organization'
            }
          }
        }
        payload = Payload.new(payload_json)

        expect(payload.repository_owner_is_organization?).to be true
      end
    end
  end

  describe '#private_repo?' do
    context 'when repo is private' do
      it 'returns true' do
        payload_json = {
          'object_attributes' => {
            'source' => {
              'visibility_level' => 0
            }
          }
        }
        payload = Payload.new(payload_json)

        expect(payload.private_repo?).to eq(true)
      end
    end

    context 'when repo is public' do
      it 'returns false' do
        payload_json = {
          'object_attributes' => {
            'source' => {
              'visibility_level' => 10
            }
          }
        }
        payload = Payload.new(payload_json)

        expect(payload.private_repo?).to eq(false)
      end
    end
  end

  describe '#build_data' do
    it 'returns a subset of original data' do
      payload_data = File.read(
        'spec/support/fixtures/pull_request_opened_event.json'
      )
      payload = Payload.new(payload_data)

      expect(payload.build_data).to eq(
        {
          'number' => 99,
          'action' => 'open',
          'pull_request' => {
            'changed_files' => 0,
            'head' => {
              'sha' => 'da1560886d4f094c3e6c9ef40349f7d38b5d27d7'
            }
          },
          'repository' => {
            'id' => 14,
            'full_name' => 'awesome_space/awesome_project',
            'private' => false,
            'owner' => {
              'id' => nil,
              'login' => nil,
              'type' => nil
            }
          }
        }
      )
    end
  end
end
