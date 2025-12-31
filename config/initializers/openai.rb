OpenAI.configure do |config|
  config.access_token = Rails.application.credentials.dig(:openai, :api_key) || ENV["OPENAI_API_KEY"]
  config.log_errors = Rails.env.development? || Rails.env.test?
end
