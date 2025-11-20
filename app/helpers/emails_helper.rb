module EmailsHelper
  ALLOWED_EMAIL_HTML_TAGS = %w[
    a abbr b blockquote br code div em h1 h2 h3 h4 h5 h6 hr i li ol p pre span strong table tbody td th thead tr u ul img
  ].freeze

  ALLOWED_EMAIL_HTML_ATTRIBUTES = %w[href title target rel src alt].freeze

  def sanitized_email_html(email)
    return if email.body_html.blank?

    sanitize(
      email.body_html,
      tags: ALLOWED_EMAIL_HTML_TAGS,
      attributes: ALLOWED_EMAIL_HTML_ATTRIBUTES
    )
  end
end
