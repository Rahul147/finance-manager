# app/services/google_gmail.rb
require "signet/oauth_2/client"
require "google/apis/gmail_v1"

class GoogleReauthNeeded < StandardError; end

module GoogleGmail
  BLACKLIST_SUBJECTS = [ "Login", "Payment Received" ].map(&:downcase)
  SCOPES             = [ Google::Apis::GmailV1::AUTH_GMAIL_READONLY ].freeze

  module_function

  def ingest_latest(acct, senders:, days: 2, unread_only: true, max: 200)
    service     = service_for(acct, scopes: SCOPES)
    q_parts     = []

    from_filter = senders.map { |e| "from:#{e}" }.join(" ")
    after_str   = (Date.current - days).strftime("%Y/%m/%d")
    q_parts << "{ #{from_filter} }" if from_filter.present?
    q_parts << "after:#{after_str}"
    q_parts << "in:unread" if unread_only
    q = q_parts.join(" ")

    list = service.list_user_messages("me", q: q, max_results: max)
    return 0 unless list&.messages

    created = 0

    list.messages.each do |m|
      next if Email.exists?(email_account_id: acct.id, message_id: m.id)
      msg = service.get_user_message("me", m.id, format: "full")
      headers = headers_hash(msg.payload.headers)
      subject = headers["Subject"].to_s
      next if blacklisted_subject?(subject)

      text, html = extract_hrml_text(msg.payload&.parts || [])

      email = Email.create!(
        user_id: acct.user_id,
        email_account_id: acct.id,
        message_id: msg.id,
        thread_id: msg.thread_id,
        subject: subject,
        from_address: headers["From"],
        to_address: headers["To"],
        sent_at: infer_sent_at(headers, msg.internal_date),
        snippet: msg.snippet,
        body_text: text,
        body_html: html,
        headers: headers.to_json,
        processed: false
      )
      # ExtractTransactionFromEmailJob.perform_later(email.id)
      created += 1
    end
  end

  def headers_hash(headers) = (headers || []).to_h { |h| [ h.name, h.value ] }

  def extract_hrml_text(parts)
    parts ||= []
    part = parts.find { |p| p.mime_type == "text/html" }
    data = part&.body&.data.to_s
    return [ nil, nil ] if data.empty?

    html = begin
      s = data.dup.force_encoding("UTF-8")
      s.valid_encoding? ? s : data.dup.force_encoding("BINARY").encode("UTF-8", invalid: :replace, undef: :replace)
    end

    doc = Nokogiri::HTML(html)
    text = doc.text.encode("UTF-8", invalid: :replace, undef: :replace).gsub(/\s+/, " ").strip
    [ text, html ]
  end

  def infer_sent_at(headers, internal_ms)
    if headers["Date"].present?
      Time.parse(headers["Date"]) rescue safe_internal_time(internal_ms)
    else
      safe_internal_time(internal_ms)
    end
  end

  def safe_internal_time(internal_ms)
    return Time.current unless internal_ms
    Time.at(internal_ms.to_i / 1000)
  end

  def blacklisted_subject?(subject)
    s = subject.to_s.downcase
    BLACKLIST_SUBJECTS.any? { |w| s.include?(w) }
  end

  # TODO: See if this can be moved to Google service (DRY)
  def service_for(acct, scopes:)
    client = Signet::OAuth2::Client.new(
      client_id: Rails.application.credentials.dig(:google, :client_id) || ENV["GOOGLE_API_CLIENT_ID"],
      client_secret: Rails.application.credentials.dig(:google, :client_secret) || ENV["GOOGLE_API_CLIENT_SECRET"],
      token_credential_uri: "https://oauth2.googleapis.com/token",
      scope: scopes,
      access_token: acct.access_token,
      refresh_token: acct.refresh_token
    )

    begin
      if acct.expired? || acct.access_token.blank?
        client.refresh!
        acct.update!(
          access_token: client.access_token,
          expires_at: Time.current + client.expires_in.to_i.seconds
        )
      end
    rescue Signet::AuthorizationError => e
      acct.update!(access_token: nil, refresh_token: nil, expires_at: nil)
      raise GoogleReauthNeeded, e.message
    end

    service = Google::Apis::GmailV1::GmailService.new
    service.authorization = client
    service
  end
end
