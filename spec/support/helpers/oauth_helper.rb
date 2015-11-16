module OauthHelper
  def stub_oauth(options = {})
    OmniAuth.config.add_mock(
      :gitlab,
      info: {
        username: options[:username],
        email: options[:email]
      },
      credentials: {
        token: options[:token]
      }
    )
  end
end
