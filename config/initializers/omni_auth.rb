OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  provider(
    :gitlab,
    Hound::GITLAB_APPLICATION_KEY,
    Hound::GITLAB_APPLICATION_SECRET,
    client_options: {
      site: Hound::GITLAB_API_URL
    }
  )
end
