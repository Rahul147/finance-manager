require "securerandom"
require "signet/oauth_2/client"
require "google/apis/gmail_v1"
require "base64"

class EmailProviderOauthsController < ApplicationController
  SCOPES = [ Google::Apis::GmailV1::AUTH_GMAIL_READONLY, "openid", "email", "profile" ].freeze

  def start
    # Defaulting to `google`
    client = oauth_client
    state = SecureRandom.hex(24)
    session[:google_oauth_state] = state
    redirect_to client.authorization_uri(state: state).to_s, allow_other_host: true
  end

  def callback
    unless params[:state] == session.delete(:google_oauth_state)
      Rails.logger.info(
        "OAuth DEBUG → base_url=#{request.base_url} " \
        "state_param=#{params[:state]} stored_state=#{stored}"
      )
      return redirect_to root_path, alert: "Invalid OAuth state."
    end

    client = oauth_client(code: params[:code])
    token = client.fetch_access_token!

    gmail = Google::Apis::GmailV1::GmailService.new
    gmail.authorization = client
    profile = gmail.get_user_profile("me")
    # acct_id = id_token_sub(token[:id_token])
    acct_id = profile.email_address

    acct = Current.user.email_accounts.find_or_initialize_by(
      provider: "google",
      provider_account_id: acct_id
    )

    # TODO: Remove hardcoded value
    acct.provider       = "google"
    # provider_account_id = acct_id
    acct.email_address  = profile.email_address
    acct.access_token   = token["access_token"]
    acct.refresh_token  = token["refresh_token"] if token["refresh_token"].present?
    acct.expires_at     = Time.current + token["expires_in"].to_i.seconds if token["expires_in"]
    acct.scope          = token["scope"] if token["scope"]
    acct.token_type     = token["token_type"] if token["token_type"]
    
    acct.save!

    redirect_to root, notice: "Google account linked."
  rescue Signet::AuthorizationError
    redirect_to root_path, alert: "Authorization failed."
  end

  private
  def oauth_client(code: nil)
    Signet::OAuth2::Client.new(
      client_id: Rails.application.credentials.dig(:google, :client_id) || ENV["GOOGLE_API_CLIENT_ID"],
      client_secret: Rails.application.credentials.dig(:google, :client_secret) || ENV["GOOGLE_API_CLIENT_SECRET"],
      authorization_uri: "https://accounts.google.com/o/oauth2/v2/auth",
      token_credential_uri: "https://oauth2.googleapis.com/token",
      scope: SCOPES,
      # TODO: Change the hardcoded URL
      redirect_uri: "http://localhost:3000/oauth/google/callback",
      code: code,
      additional_parameters: {
        access_type: "offline",
        prompt: "consent",
        include_granted_scopes: "true"
      }
    )
  end

  def id_token_sub(id_token)
    return unless id_token
    payload = id_token.split(".")[1]
    JSON.parse(Base64.urlsafe_decode64(payload))["sub"]
  rescue
    nil
  end
end
