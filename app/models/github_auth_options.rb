class GithubAuthOptions
  def initialize(env)
    @request = Rack::Request.new(env)
  end

  def to_hash
    { scope: 'api' }
  end
end
